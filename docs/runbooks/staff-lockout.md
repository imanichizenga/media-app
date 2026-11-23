# Staff cannot sign in

- **Lost factor:** another administrator opens Staff → person → *Reset password and second step* (needs approval in production).
- **Locked out by attempts:** wait for the lockout (default 15 minutes). It applies to that account from that address.
- **Allowlist mistake:** run the `migrate` task with `python manage.py break_glass_disable_allowlist --reason "..."`. It is audited and opens the WAF set too.
- **Both Super Admins gone:** `bootstrap_super_admin` works while fewer than two active Super Admins exist.
- **Redis down:** sign-in fails closed. Existing sessions keep working.
