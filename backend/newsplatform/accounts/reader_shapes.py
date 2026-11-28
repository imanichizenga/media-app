"""What readers' endpoints take and give (ADR-0050): the OpenAPI document the clients are made from."""

from typing import Any

from rest_framework import serializers

from newsplatform.common.locales import Locale
from newsplatform.content.public_shapes import CardSerializer, PublicPolicySerializer

S = serializers


class MethodsSerializer(S.Serializer[Any]):
    phone = S.BooleanField()
    google = S.BooleanField()
    google_client_id = S.CharField()
    apple = S.BooleanField()
    apple_services_id = S.CharField()
    countries = S.ListField(child=S.CharField())
    code_length = S.IntegerField()
    resend_seconds = S.IntegerField()
    terms_version = S.CharField()
    local_sms = S.BooleanField(help_text="Development only: the code comes back in the answer, never by SMS.")


class CodeRequestSerializer(S.Serializer[Any]):
    phone = S.CharField(help_text="As the reader typed it; 0712 345 678 is +255712345678.")
    locale = S.ChoiceField(choices=Locale.choices, required=False)


class CodeSentSerializer(S.Serializer[Any]):
    challenge = S.UUIDField()
    phone = S.CharField()
    resend_in = S.IntegerField()
    expires_in = S.IntegerField()
    local_code = S.CharField(required=False)


class CodeVerifySerializer(S.Serializer[Any]):
    challenge = S.UUIDField()
    code = S.CharField()
    device = S.CharField(required=False)


class ProviderSignInSerializer(S.Serializer[Any]):
    id_token = S.CharField(required=False, help_text="From the app's SDK.")
    code = S.CharField(required=False, help_text="From the website's redirect.")
    redirect_uri = S.CharField(required=False)
    code_verifier = S.CharField(required=False)
    nonce = S.CharField(required=False)
    name = S.CharField(required=False, help_text="Apple sends the name once, outside the token.")
    device = S.CharField(required=False)


class ReaderSerializer(S.Serializer[Any]):
    id = S.UUIDField()
    display_name = S.CharField()
    username = S.CharField()
    initial = S.CharField()
    phone = S.CharField()
    email = S.CharField()
    locale = S.ChoiceField(choices=Locale.choices)
    methods = S.ListField(child=S.ChoiceField(choices=["phone", "google", "apple"]))
    onboarding = S.BooleanField(help_text="A name and the terms are still to come.")
    hide_from_readers = S.BooleanField()
    bio = S.CharField(allow_blank=True)
    contact_email = S.CharField(allow_blank=True, help_text="Typed by the reader; never used to sign in.")
    joined = S.DateField()


class SignedInSerializer(S.Serializer[Any]):
    access = S.CharField()
    refresh = S.CharField()
    expires_in = S.IntegerField()
    created = S.BooleanField(required=False)
    user = ReaderSerializer()


class RefreshSerializer(S.Serializer[Any]):
    refresh = S.CharField()
    device = S.CharField(required=False)


class ProfileSerializer(S.Serializer[Any]):
    display_name = S.CharField(required=False)
    username = S.CharField(required=False)
    locale = S.ChoiceField(choices=Locale.choices, required=False)
    accept_terms = S.BooleanField(required=False)
    hide_from_readers = S.BooleanField(required=False)
    bio = S.CharField(required=False, allow_blank=True, max_length=160)
    contact_email = S.CharField(required=False, allow_blank=True, max_length=254)


class DeleteSerializer(S.Serializer[Any]):
    confirm = S.ChoiceField(choices=["delete"])


class DeletionSerializer(S.Serializer[Any]):
    grace_days = S.IntegerField()


class CountsSerializer(S.Serializer[Any]):
    views = S.IntegerField(help_text="Openings; one device counts once in 30 minutes.")
    likes = S.IntegerField()
    comments = S.IntegerField()
    bookmarks = S.IntegerField()


class PostStateSerializer(CountsSerializer):
    readers = S.IntegerField(help_text="Distinct people who opened it.")
    liked = S.BooleanField()
    bookmarked = S.BooleanField()
    likes_on = S.BooleanField(help_text="The story allows likes now: a count it does not allow is not shown.")
    comments_on = S.BooleanField(help_text="The story's comments are not closed.")


class LikedSerializer(CountsSerializer):
    liked = S.BooleanField()


class BookmarkedSerializer(CountsSerializer):
    bookmarked = S.BooleanField()


class CommentAuthorSerializer(S.Serializer[Any]):
    name = S.CharField()
    username = S.CharField()
    initial = S.CharField()
    is_writer = S.BooleanField(help_text="Wrote the story: a badge.")


class CommentSerializer(S.Serializer[Any]):
    id = S.UUIDField()
    body = S.CharField()
    created_at = S.DateTimeField()
    author = CommentAuthorSerializer()
    like_count = S.IntegerField()
    reply_count = S.IntegerField()
    liked = S.BooleanField()
    mine = S.BooleanField()
    pinned = S.BooleanField()
    held = S.BooleanField(help_text="Waiting for a moderator; only its writer sees it.")
    parent = S.UUIDField(allow_null=True)  # type: ignore[assignment]  # a declared field, moved aside by DRF


class CommentPageSerializer(S.Serializer[Any]):
    policy = PublicPolicySerializer()
    count = S.IntegerField()
    results = CommentSerializer(many=True)
    next_cursor = S.CharField(allow_null=True)


class NewCommentSerializer(S.Serializer[Any]):
    body = S.CharField(max_length=2000)
    parent = S.UUIDField(required=False, allow_null=True)  # type: ignore[assignment]


class CommentLikedSerializer(S.Serializer[Any]):
    liked = S.BooleanField()
    like_count = S.IntegerField()


class FollowingSerializer(S.Serializer[Any]):
    following = S.BooleanField()


class FollowSerializer(S.Serializer[Any]):
    kind = S.ChoiceField(choices=["author", "category"])
    target = S.UUIDField()


class FollowListSerializer(S.Serializer[Any]):
    results = FollowSerializer(many=True)


class CardListSerializer(S.Serializer[Any]):
    results = CardSerializer(many=True)


class ExportSerializer(S.Serializer[Any]):
    account = ReaderSerializer()
    identities = S.ListField(child=S.DictField())
    consents = S.ListField(child=S.DictField())
    likes = S.ListField(child=S.DictField())
    bookmarks = S.ListField(child=S.DictField())
    comments = S.ListField(child=S.DictField())
    follows = S.ListField(child=S.DictField())


class OpenedSerializer(S.Serializer[Any]):
    device = S.CharField(required=False, help_text="A guest's random id, kept by the browser or app.")


class ReaderEntrySerializer(S.Serializer[Any]):
    name = S.CharField()
    username = S.CharField()
    initial = S.CharField()
    at = S.DateTimeField()


class ReadersSerializer(S.Serializer[Any]):
    readers = S.IntegerField()
    views = S.IntegerField()
    guests = S.IntegerField(help_text="Readers without an account, counted but never named.")
    results = ReaderEntrySerializer(many=True)
    next_cursor = S.CharField(allow_null=True)
