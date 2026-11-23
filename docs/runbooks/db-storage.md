# Database storage

Autoscaling grows to 5x. If it is at the limit, raise `db_allocated_gb` in Terraform and apply. Largest tables: `audit_auditentry`, `integrations_integrationcall`, `staff_security_authevent`.
