from django.apps import AppConfig


class TaxonomyConfig(AppConfig):
    name = "newsplatform.taxonomy"

    def ready(self) -> None:
        from newsplatform.rbac.registry import register_scope
        from newsplatform.taxonomy.selectors import scope_chain

        register_scope("category", scope_chain)
