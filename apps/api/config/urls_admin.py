from django.urls import path, re_path

from newsplatform.approvals import api as approvals
from newsplatform.audit import api as audit
from newsplatform.common import health
from newsplatform.integrations import api as integrations
from newsplatform.rbac import api as rbac
from newsplatform.realtime import api as realtime
from newsplatform.site_config import api as site
from newsplatform.staff_security import api as staff

API = "api/v1/"
urlpatterns = [
    path("health/live", health.live),
    path("health/ready", health.ready),
    path(API + "auth/login", staff.LoginView.as_view()),
    path(API + "auth/session", staff.SessionView.as_view()),
    path(API + "auth/invite/accept", staff.AcceptInviteView.as_view()),
    path(API + "auth/reset/complete", staff.CompleteResetView.as_view()),
    path(API + "auth/mfa/totp/verify", staff.TotpVerifyView.as_view()),
    path(API + "auth/mfa/recovery/verify", staff.RecoveryVerifyView.as_view()),
    path(API + "auth/mfa/passkey/options", staff.PasskeyAuthOptionsView.as_view()),
    path(API + "auth/mfa/passkey/verify", staff.PasskeyAuthView.as_view()),
    path(API + "auth/mfa/passkey/register/options", staff.PasskeyRegisterOptionsView.as_view()),
    path(API + "auth/mfa/passkey/register", staff.PasskeyRegisterView.as_view()),
    path(API + "auth/mfa/totp/begin", staff.TotpBeginView.as_view()),
    path(API + "auth/mfa/totp/confirm", staff.TotpConfirmView.as_view()),
    path(API + "me/security", staff.MySecurityView.as_view()),
    path(API + "me/password", staff.PasswordView.as_view()),
    path(API + "me/recovery-codes", staff.RecoveryCodesView.as_view()),
    re_path(r"^api/v1/me/factors/(?P<factor>totp|[0-9a-f-]{36})$", staff.FactorView.as_view()),
    path(API + "me/sessions/<uuid:session_id>", staff.MySessionView.as_view()),
    path(API + "realtime/ticket", realtime.RealtimeTicketView.as_view()),
    path(API + "staff", staff.StaffListView.as_view()),
    path(API + "staff/invites", staff.StaffInviteView.as_view()),
    path(API + "staff/invites/<uuid:invite_id>", staff.StaffInviteItemView.as_view()),
    path(API + "staff/<uuid:user_id>/reset", staff.StaffResetView.as_view()),
    path(API + "staff/<uuid:user_id>/status", staff.StaffStatusView.as_view()),
    path(API + "staff/<uuid:user_id>/logout", staff.StaffLogoutView.as_view()),
    path(API + "roles", rbac.RoleListView.as_view()),
    path(API + "roles/<uuid:role_id>", rbac.RoleItemView.as_view()),
    path(API + "assignments", rbac.AssignmentListView.as_view()),
    path(API + "assignments/<uuid:assignment_id>", rbac.AssignmentItemView.as_view()),
    path(API + "approvals", approvals.ApprovalListView.as_view()),
    re_path(
        r"^api/v1/approvals/(?P<approval_id>[0-9a-f-]{36})/(?P<decision>approve|reject)$",
        approvals.ApprovalDecisionView.as_view(),
    ),
    path(API + "audit", audit.AuditListView.as_view()),
    path(API + "audit/verify", audit.AuditVerifyView.as_view()),
    path(API + "audit/export", audit.AuditExportView.as_view()),
    path(API + "logs/auth", staff.AuthEventListView.as_view()),
    path(API + "logs/integrations", integrations.IntegrationCallListView.as_view()),
    path(API + "settings/<slug:key>", site.SettingsView.as_view()),
    path(API + "integrations", integrations.IntegrationListView.as_view()),
    path(API + "integrations/runs/<uuid:run_id>", integrations.IntegrationTestRunView.as_view()),
    path(API + "integrations/<slug:key>", integrations.IntegrationDetailView.as_view()),
    path(
        API + "integrations/<slug:key>/versions/<int:number>/test", integrations.IntegrationTestView.as_view()
    ),
    path(
        API + "integrations/<slug:key>/versions/<int:number>/activate",
        integrations.IntegrationActivateView.as_view(),
    ),
]
