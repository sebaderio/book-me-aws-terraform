import os
import pathlib
import shutil
import uuid

from django import dispatch
from django.conf import settings
from django.db.models import signals

from barber import models
from core import utils
from tasks import image_handling
from websockets import triggers


@dispatch.receiver(signals.post_save, sender=models.ServiceOffer)
@utils.prevent_signal_recursion
def generate_thumbnail_from_image(  # type:ignore # pylint: disable=unused-argument
    sender, instance, *args, **kwargs
) -> None:
    if not instance.image and instance.thumbnail:
        instance.thumbnail.delete()
    elif instance.image and (
        not instance.thumbnail or instance.image.name != instance.thumbnail.name
    ):
        image_path = pathlib.Path(instance.image.path)
        new_image_name = uuid.uuid4().hex + image_path.suffix
        new_image_path = os.path.join(image_path.parent, new_image_name)
        os.rename(image_path, new_image_path)
        instance.image = os.path.join(models.SERVICE_OFFER_IMAGE_PATH, new_image_name)
        thumbnail_path = os.path.join(settings.MEDIA_ROOT, models.SERVICE_OFFER_THUMBNAIL_PATH)
        if not os.path.exists(thumbnail_path):
            os.makedirs(thumbnail_path)
        shutil.copy(new_image_path, thumbnail_path)
        instance.thumbnail = os.path.join(models.SERVICE_OFFER_THUMBNAIL_PATH, new_image_name)
        _resize_thumbnail_if_too_big(instance)


def _resize_thumbnail_if_too_big(instance: models.ServiceOffer) -> None:
    if (
        instance.thumbnail.width > models.MAX_THUMBNAIL_WIDTH
        or instance.thumbnail.height > models.MAX_THUMBNAIL_HEIGHT
    ):
        image_handling.resize_image_at_path.delay(
            instance.thumbnail.path, (models.MAX_THUMBNAIL_WIDTH, models.MAX_THUMBNAIL_HEIGHT)
        )


@dispatch.receiver(signals.post_delete, sender=models.ServiceUnavailability)
def trigger_post_delete_unavailabilities_channel(  # type:ignore # pylint: disable=unused-argument
    sender, instance, *args, **kwargs
) -> None:
    triggers.trigger_service_unavailabilities_channel(instance.service_offer_id)


@dispatch.receiver(signals.post_save, sender=models.ServiceUnavailability)
@utils.prevent_signal_recursion
def trigger_post_save_unavailabilities_channel(  # type:ignore # pylint: disable=unused-argument
    sender, instance, *args, **kwargs
) -> None:
    triggers.trigger_service_unavailabilities_channel(instance.service_offer_id)
