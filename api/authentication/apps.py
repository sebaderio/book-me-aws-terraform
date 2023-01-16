from django.apps import AppConfig


class AuthenticationConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'authentication'

    def ready(self) -> None:
        import authentication.signals  # noqa pylint: disable=unused-import, import-outside-toplevel, no-name-in-module, import-error
