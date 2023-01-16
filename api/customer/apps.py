from django.apps import AppConfig
from django.utils.translation import gettext_lazy as __


class CustomerConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'customer'
    verbose_name = __('Customers')

    def ready(self) -> None:
        import customer.signals  # noqa pylint: disable=unused-import, import-outside-toplevel, no-name-in-module, import-error
