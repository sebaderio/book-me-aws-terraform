from django.contrib import admin, auth

from authentication import utils

User = auth.get_user_model()


@admin.register(User)
class UserAdmin(admin.ModelAdmin):

    list_display = (
        'name',
        'surname',
        'email',
        'account_status',
        'account_type',
    )
    list_filter = (utils.AccountStatusFilter, utils.AccountTypeFilter)
    search_fields = ('name', 'surname', 'email')
    exclude = ('password',)

    def get_form(self, request, obj=None, change=False, **kwargs):  # type:ignore
        form = super().get_form(request, obj, **kwargs)
        is_superuser = request.user.is_superuser
        disabled_fields = set()

        # Prevent changing permissions without using groups
        if not is_superuser:
            disabled_fields |= {
                'account_type',
                'is_superuser',
                'user_permissions',
            }

        # Prevent users changing own permissions
        if not is_superuser and obj is not None and obj == request.user:
            disabled_fields |= {
                'account_type',
                'is_staff',
                'is_superuser',
                'groups',
                'user_permissions',
            }

        for field in disabled_fields:
            if field in form.base_fields:
                form.base_fields[field].disabled = True

        return form
