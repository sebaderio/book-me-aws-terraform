from django.apps import AppConfig
from django.utils.translation import gettext_lazy as __


class BarberConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'barber'
    verbose_name = __('Hairdressers')

    def ready(self) -> None:
        import barber.signals  # noqa pylint: disable=unused-import, import-outside-toplevel, no-name-in-module, import-error
