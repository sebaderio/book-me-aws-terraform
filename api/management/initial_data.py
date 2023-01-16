from django.contrib.auth.management import create_permissions
from django.contrib.auth.models import Group, Permission


def populate_groups(apps, schema_editor) -> None:  # type:ignore
    '''
    This function is run in migrations/0001_initial_data.py as an initial
    data migration at project initialization. it sets up some basic model-level
    permissions for different groups when the project is initialised.

    To specify object-level permissions one may use:
    https://github.com/django-guardian/django-guardian
    '''

    user_roles = ['Barber']
    for name in user_roles:
        Group.objects.create(name=name)

    # Permissions have to be created before applying them
    for app_config in apps.get_app_configs():
        app_config.models_module = True
        create_permissions(app_config, verbosity=0)
        app_config.models_module = None

    barber_permissions = [
        'add_serviceoffer',
        'change_serviceoffer',
        'view_serviceoffer',
        'add_serviceunavailability',
        'change_serviceunavailability',
        'delete_serviceunavailability',
        'view_serviceunavailability',
        'change_serviceorder',
        'view_serviceorder',
    ]

    barber_perms = Permission.objects.filter(codename__in=barber_permissions).all()
    Group.objects.get(name='Barber').permissions.add(*barber_perms)
