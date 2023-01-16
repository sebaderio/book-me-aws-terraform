from datetime import date, datetime

from django.db.models import query

from barber import models as barber_models
from customer import models as customer_models, value_objects


def get_active_service_orders(service_offer_id: int) -> query.QuerySet:
    return (
        customer_models.ServiceOrder.objects.filter(
            offer_id=service_offer_id, service_time__gt=datetime.now()
        )
        .exclude(status=value_objects.ServiceOrderStatus.CLOSED.name)
        .values('service_time')
        .order_by('service_time')
        .all()
    )


def serialize_service_orders(service_orders: query.QuerySet) -> list:
    return [
        service_order['service_time'].replace(tzinfo=None).isoformat()
        for service_order in service_orders
    ]


def get_future_service_unavailabilities(service_offer_id: int) -> query.QuerySet:
    return (
        barber_models.ServiceUnavailability.objects.filter(
            service_offer_id=service_offer_id, end_date__gte=date.today()
        )
        .values('start_date', 'end_date')
        .order_by('start_date')
        .all()
    )


def serialize_service_unavailabilities(service_unavailabilities: query.QuerySet) -> list:
    serialized_unavailabilities = []
    for service_unavailability in service_unavailabilities:
        serialized_unavailabilities.append(
            {key: service_unavailability[key].isoformat() for key in service_unavailability.keys()}
        )
    return serialized_unavailabilities
