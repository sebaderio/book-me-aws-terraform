from typing import Any

from django.db.models import query
from django.utils.translation import gettext_lazy as __
from rest_framework import filters, generics, request, response, status, viewsets

from barber import models, pagination, serializers, value_objects


class ServiceOfferViewSet(viewsets.ReadOnlyModelViewSet):
    def retrieve(self, request: request.Request, *args: Any, **kwargs: Any) -> response.Response:
        service_offer = models.ServiceOffer.objects.filter(
            id=kwargs['id'], status=value_objects.OfferStatus.ACTIVE.name
        ).first()
        if service_offer is None:
            return response.Response(
                {'detail': __('No service offer found with specified id.')},
                status=status.HTTP_404_NOT_FOUND,
            )
        # NOTE: 'request' must be passed in the serializer context when you want to get
        # full image URL instead of the relative one, as it is saved in db.
        return response.Response(
            serializers.ServiceOfferSerializer(service_offer, context={'request': request}).data,
            status=status.HTTP_200_OK,
        )


class ServiceOfferListView(generics.ListAPIView):
    pagination_class = pagination.ServiceOfferNumberPagination
    serializer_class = serializers.ServiceOfferListSerializer
    filter_backends = (filters.SearchFilter, filters.OrderingFilter)
    search_fields = ('address', 'barber_name', 'city')
    ordering = ('-updated_at',)

    def get_queryset(self) -> query.QuerySet:
        return models.ServiceOffer.objects.filter(
            status=value_objects.OfferStatus.ACTIVE.name
        ).all()


# Only fields specified in the view's serializer (default) or explicitly specified
# in the view (ordering_fields param) can be specified to order objects by in the URL query params.
# Default ordering can be specified in the view (ordering param).
# In this case all fields can be specified, even these not included in the serializer.
# Seems that ordering in URL params overrides, not concatenates with the default (ordering param).

# Search filter by default runs a non case-sensitive, partial, text based search. Check DRF
# filtering, pagination and ordering docs to get more info. There are many built-in features.
