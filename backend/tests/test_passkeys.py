import pytest

from newsplatform.staff_security.models import Passkey
from tests.authenticator import Authenticator

pytestmark = pytest.mark.django_db
P = "auth/mfa/passkey"


def register(api, device, **kw):
    options = api.post(f"{P}/register/options").json()
    return api.post(f"{P}/register", {"credential": device.create(options, **kw), "name": "Laptop"})


@pytest.fixture
def owner(make_staff, new_api):
    user, api, device = make_staff(), new_api(), Authenticator()
    api.login(user)
    res = register(api, device)
    assert res.status_code == 200, res.content
    assert res.json()["session"]["stage"] == "active" and len(res.json()["recovery_codes"]) == 10
    return user, api, device


@pytest.fixture
def challenged(owner, new_api):
    api = new_api()
    assert api.login(owner[0]).json()["mfa_methods"] == ["passkey", "recovery"]
    return api


def options(api):
    return api.post(f"{P}/options").json()


def verify(api, credential):
    return api.post(f"{P}/verify", {"credential": credential, "name": ""})


def test_sign_in(owner, challenged):
    res = verify(challenged, owner[2].get(options(challenged)))
    assert res.status_code == 200 and res.json()["stage"] == "active"
    assert Passkey.objects.get().last_used_at


def test_registration_without_user_verification_is_refused(make_staff, new_api):
    api = new_api()
    api.login(make_staff())
    assert register(api, Authenticator(), uv=False).status_code == 401
    assert not Passkey.objects.exists()


def test_sign_in_without_user_verification_is_refused(owner, challenged):
    assert verify(challenged, owner[2].get(options(challenged), uv=False)).status_code == 401


@pytest.mark.parametrize(("attr", "value"), [("origin", "https://evil.example"), ("rp_id", "evil.example")])
def test_phishing_origin_is_refused(owner, challenged, attr, value):
    setattr(owner[2], attr, value)
    assert verify(challenged, owner[2].get(options(challenged))).status_code == 401


def test_response_cannot_be_replayed(owner, challenged, new_api):
    cred = owner[2].get(options(challenged))
    assert verify(challenged, cred).status_code == 200
    assert verify(challenged, cred).json()["code"] == "challenge_expired"
    again = new_api()
    again.login(owner[0])
    options(again)
    assert verify(again, cred).status_code == 401


def test_replay_is_refused_for_synced_passkeys_whose_counter_is_always_zero(owner, challenged):
    """Regression: promoting the session used to restore the consumed challenge, leaving only the counter."""
    user, _, device = owner
    Passkey.objects.update(sign_count=0)
    device.count = -1  # the next assertion reports 0, as iCloud and Google passkeys always do
    cred = device.get(options(challenged))
    assert verify(challenged, cred).status_code == 200
    assert user.staff_sessions.filter(challenge__isnull=False).count() == 0
    assert verify(challenged, cred).json()["code"] == "challenge_expired"


def test_registration_challenge_cannot_be_used_to_sign_in(owner):
    _, api, device = owner
    opts = api.post(f"{P}/register/options").json()
    assert verify(api, device.get(opts)).json()["code"] == "challenge_expired"


def test_another_users_passkey_is_refused(owner, make_staff, new_api):
    other, theirs, device = make_staff(), new_api(), Authenticator()
    theirs.login(other)
    register(theirs, device)
    api = new_api()
    api.login(owner[0])
    assert verify(api, device.get(options(api))).status_code == 401


def test_cloned_authenticator_counter_is_refused(owner, challenged):
    owner[2].count = -1
    Passkey.objects.update(sign_count=50)
    assert verify(challenged, owner[2].get(options(challenged))).status_code == 401


def test_wrong_key_with_the_right_id(owner, challenged):
    fake = Authenticator()
    fake.cred_id = owner[2].cred_id
    assert verify(challenged, fake.get(options(challenged))).status_code == 401


@pytest.mark.parametrize("junk", [{}, {"rawId": "!!"}, {"rawId": "AAAA", "response": None}, {"rawId": 5}])
def test_malformed_credentials_are_401_not_500(owner, challenged, junk):
    options(challenged)
    assert verify(challenged, junk).status_code == 401


def test_same_passkey_twice(owner):
    assert register(owner[1], owner[2]).json()["code"] == "passkey_exists"


def test_remove_one_of_two(owner):
    _, api, _ = owner
    second = register(api, Authenticator())
    assert second.status_code == 200 and second.json()["recovery_codes"] == []
    ids = list(Passkey.objects.values_list("pk", flat=True))
    assert api.delete(f"me/factors/{ids[0]}").status_code == 204
    assert api.delete(f"me/factors/{ids[1]}").json()["code"] == "last_factor"
