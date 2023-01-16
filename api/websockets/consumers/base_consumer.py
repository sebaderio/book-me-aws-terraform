import abc
import logging

from asgiref.sync import sync_to_async
from channels import consumer

logger = logging.getLogger('django')


class BaseConsumer(consumer.AsyncConsumer):
    @abc.abstractmethod
    async def websocket_connect(self, event: dict) -> None:
        pass

    async def websocket_receive(self, event: dict) -> None:
        '''Handle message sent by user. No logic for this as for now.'''
        data = event.get('text', None)
        if not data:
            await self.log_debug('No data in the message')
        await self.log_debug(data)

    @sync_to_async
    def log_debug(self, message: str) -> None:
        '''Log debug info asynchronously.'''
        logger.debug(message)

    @sync_to_async
    def log_warning(self, message: str) -> None:
        '''Log warning asynchronously.'''
        logger.warning(message)

    async def websocket_disconnect(self, event: dict) -> None:
        '''Close channel connection.'''
        raise consumer.StopConsumer()
