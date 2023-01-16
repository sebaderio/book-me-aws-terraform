'''
ASGI config for core project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/4.0/howto/deployment/asgi/
'''
# flake8: noqa # pylint: disable=C0411,C0413
import os

from channels import auth, routing
from django import urls
from django.core import asgi

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.config.settings')
# Initialize Django ASGI application early to ensure the AppRegistry
# is populated before importing code that may import ORM models.
django_asgi_app = asgi.get_asgi_application()

from websockets import consumers

application = routing.ProtocolTypeRouter(
    {
        'http': django_asgi_app,
        'websocket': auth.AuthMiddlewareStack(
            routing.URLRouter(
                [
                    urls.re_path(
                        r'^websockets/service_orders/(?P<offer_id>\d+)/$',
                        consumers.ServiceOrdersConsumer.as_asgi(),
                    ),
                    urls.re_path(
                        r'^websockets/service_unavailabilities/(?P<offer_id>\d+)/$',
                        consumers.ServiceUnavailabilitiesConsumer.as_asgi(),
                    ),
                ]
            )
        ),
    }
)
