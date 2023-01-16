import os
from typing import Tuple

from PIL import Image  # type: ignore

from tasks import celery


@celery.app.task
def resize_image_at_path(path: str, output_size: Tuple[int, int]) -> None:
    if os.path.isfile(path):
        image = Image.open(path)
        image.thumbnail(output_size)
        image.save(path)
