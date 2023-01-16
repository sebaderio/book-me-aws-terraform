import os
import pkgutil

import celery  # type:ignore

import tasks

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.config.settings')

path = tasks.__path__
prefix = f'{tasks.__name__}.'
submodules_with_tasks = [
    modname for _importer, modname, is_pkg in pkgutil.iter_modules(path, prefix) if is_pkg
]

app = celery.Celery('tasks', include=submodules_with_tasks)

# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings', namespace='CELERY')
