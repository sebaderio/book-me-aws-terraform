import json

from asgiref import sync
from channels import layers

from websockets import templates, utils


def trigger_service_orders_channel(service_offer_id: int) -> None:
    service_orders = utils.get_active_service_orders(service_offer_id)
    serialized_orders = utils.serialize_service_orders(service_orders)
    _send_service_orders_notification(serialized_orders, service_offer_id)


def _send_service_orders_notification(data: list, service_offer_id: int) -> None:
    channel_layer = layers.get_channel_layer()
    message = {"type": "service_orders_message", "text": json.dumps(data)}
    sync.async_to_sync(channel_layer.group_send)(  # type:ignore
        templates.SERVICE_ORDERS_GROUP.format(service_offer_id), message
    )


def trigger_service_unavailabilities_channel(service_offer_id: int) -> None:
    service_unavailabilities = utils.get_future_service_unavailabilities(service_offer_id)
    serialized_unavailabilities = utils.serialize_service_unavailabilities(service_unavailabilities)
    _send_service_unavailabilities_notification(serialized_unavailabilities, service_offer_id)


def _send_service_unavailabilities_notification(data: list, service_offer_id: int) -> None:
    channel_layer = layers.get_channel_layer()
    message = {"type": "service_unavailabilities_message", "text": json.dumps(data)}
    sync.async_to_sync(channel_layer.group_send)(  # type:ignore
        templates.SERVICE_UNAVAILABILITIES_GROUP.format(service_offer_id), message
    )
