# type:ignore
from datetime import date, datetime, timedelta

from django.contrib import admin
from django.utils import safestring
from django.utils.translation import gettext_lazy as __

from barber import models as barber_models, utils, value_objects as barber_value_objects
from customer import models as customer_models, value_objects as customer_value_objects


class PendingServiceOrderInline(admin.TabularInline):
    model = customer_models.ServiceOrder
    max_num = 0
    raw_id_fields = ('customer',)
    readonly_fields = (
        'token',
        'service_time',
        'customer',
    )
    verbose_name = __('Pending Service Order')
    verbose_name_plural = __('Pending Service Orders')

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        now_minus_30_min = datetime.now() - timedelta(minutes=30)
        return (
            qs.filter(service_time__gt=now_minus_30_min)
            .exclude(status=customer_value_objects.ServiceOrderStatus.CLOSED.name)
            .order_by('service_time')
        )


class ServiceUnavailabilityInline(admin.TabularInline):
    model = barber_models.ServiceUnavailability
    extra = 0
    verbose_name = __('Service Unavailability')
    verbose_name_plural = __('Service Unavailabilities')

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.filter(end_date__gte=date.today()).order_by('start_date')


@admin.action(description=__('Activate selected service offers'))
def make_active(modeladmin, request, queryset):  # pylint: disable=unused-argument
    '''Change status of selected offers to ACTIVE.'''
    queryset.update(status=barber_value_objects.OfferStatus.ACTIVE.name)


@admin.action(description=__('Close selected service offers'))
def make_closed(modeladmin, request, queryset):  # pylint: disable=unused-argument
    '''Change status of selected offers to CLSOED.'''
    queryset.update(status=barber_value_objects.OfferStatus.CLOSED.name)


@admin.action(description=__('Hide selected service offers'))
def make_hidden(modeladmin, request, queryset):  # pylint: disable=unused-argument
    '''Change status of selected offers to HIDDEN.'''
    queryset.update(status=barber_value_objects.OfferStatus.HIDDEN.name)


@admin.register(barber_models.ServiceOffer)
class ServiceOfferAdmin(admin.ModelAdmin):
    list_display = (
        'barber_name',
        'city',
        'address',
        'description',
        'price',
        'open_hours',
        'working_days',
        'status',
        'barber_image',
    )
    exclude = ('thumbnail',)
    inlines = (ServiceUnavailabilityInline, PendingServiceOrderInline)
    list_filter = (utils.OfferStatusFilter, utils.OpenHoursFilter, utils.WorkingDaysFilter)
    actions = (make_active, make_closed, make_hidden)
    raw_id_fields = ('author',)
    search_fields = ('barber_name', 'city', 'address')

    def get_exclude(self, request, obj=None):
        if not request.user.is_admin:
            return self.exclude + ('author',) if self.exclude is not None else ('author',)
        return self.exclude

    def get_readonly_fields(self, request, obj=None):
        if obj is not None:
            return self.readonly_fields + ('image_view',)
        return self.readonly_fields

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if not request.user.is_admin:
            return qs.filter(author=request.user)
        return qs

    def save_model(self, request, obj, form, change):
        if obj.author_id is None and not request.user.is_admin:
            obj.author_id = request.user.id
        obj.save()

    def barber_image(self, obj):  # pylint: disable=R1710
        if obj is not None and obj.thumbnail:
            return safestring.mark_safe(
                '<a href={url}><img src="{url}" width={width} height={height} /></a>'.format(
                    url=obj.thumbnail.url,
                    width=obj.thumbnail.width / 2.5,
                    height=obj.thumbnail.height / 2.5,
                )
            )

    def image_view(self, obj):  # pylint: disable=R1710
        if obj is not None and obj.thumbnail:
            return safestring.mark_safe(
                '<a href={url}><img src="{url}" width={width} height={height} /></a>'.format(
                    url=obj.thumbnail.url,
                    width=obj.thumbnail.width,
                    height=obj.thumbnail.height,
                )
            )
