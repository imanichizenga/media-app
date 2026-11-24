from django.db import migrations

FORWARD = """
CREATE FUNCTION audit_reject_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit history is append-only (% on %)', TG_OP, TG_TABLE_NAME USING ERRCODE = 'insufficient_privilege';
END $$;
CREATE TRIGGER audit_entry_no_change BEFORE UPDATE OR DELETE ON audit_auditentry
  FOR EACH ROW EXECUTE FUNCTION audit_reject_mutation();
CREATE TRIGGER audit_entry_no_truncate BEFORE TRUNCATE ON audit_auditentry
  FOR EACH STATEMENT EXECUTE FUNCTION audit_reject_mutation();
CREATE TRIGGER audit_anchor_no_change BEFORE UPDATE OR DELETE ON audit_chainanchor
  FOR EACH ROW EXECUTE FUNCTION audit_reject_mutation();
CREATE TRIGGER audit_anchor_no_truncate BEFORE TRUNCATE ON audit_chainanchor
  FOR EACH STATEMENT EXECUTE FUNCTION audit_reject_mutation();
"""
REVERSE = """
DROP TRIGGER audit_entry_no_change ON audit_auditentry;
DROP TRIGGER audit_entry_no_truncate ON audit_auditentry;
DROP TRIGGER audit_anchor_no_change ON audit_chainanchor;
DROP TRIGGER audit_anchor_no_truncate ON audit_chainanchor;
DROP FUNCTION audit_reject_mutation();
"""


class Migration(migrations.Migration):
    dependencies = [("audit", "0001_initial")]
    operations = [migrations.RunSQL(FORWARD, REVERSE)]
