from django import dispatch
from django.db.models import signals

from core import utils
from customer import models
from websockets import triggers


@dispatch.receiver(signals.post_save, sender=models.ServiceOrder)
@utils.prevent_signal_recursion
def trigger_service_orders_channel(  # type:ignore # pylint: disable=unused-argument
    sender, instance, *args, **kwargs
) -> None:
    triggers.trigger_service_orders_channel(instance.offer_id)
