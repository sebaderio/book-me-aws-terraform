import json
import logging

from channels.db import database_sync_to_async
from django.db.models import query

from websockets import consumers, templates, utils

logger = logging.getLogger('django')


class ServiceOrdersConsumer(consumers.BaseConsumer):
    async def websocket_connect(self, event: dict) -> None:  # pylint: disable=unused-argument
        '''Connect new user to the group or create a new channel group.'''
        service_offer_id = int(self.scope['url_route']['kwargs']['offer_id'])
        group_name = templates.SERVICE_ORDERS_GROUP.format(service_offer_id)
        await self.channel_layer.group_add(group_name, self.channel_name)
        await self.send({'type': 'websocket.accept'})
        await self.log_debug(f'New user connected to the "{group_name}" channel group.')
        await self._send_notification_to_all_subscribed(service_offer_id)

    async def _send_notification_to_all_subscribed(self, service_offer_id: int) -> None:
        service_orders = await self._get_active_service_orders(service_offer_id)
        serialized_orders = await self._serialize_service_orders(service_orders)
        new_message = await self._prepare_new_message(serialized_orders)
        await self.channel_layer.group_send(
            templates.SERVICE_ORDERS_GROUP.format(service_offer_id), new_message
        )
        await self.log_debug(f'New message sent "{new_message}"')

    async def _prepare_new_message(self, data: list) -> dict:
        return {
            'type': 'service_orders_message',
            'text': json.dumps(data),
        }

    @database_sync_to_async
    def _get_active_service_orders(self, service_offer_id: int) -> query.QuerySet:
        return utils.get_active_service_orders(service_offer_id)

    @database_sync_to_async
    def _serialize_service_orders(self, service_orders: query.QuerySet) -> list:
        return utils.serialize_service_orders(service_orders)

    async def service_orders_message(self, event: dict) -> None:
        '''Send the actual message.'''
        await self.send({'type': 'websocket.send', 'text': event['text']})
