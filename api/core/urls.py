'''core URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
'''
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

admin.site.site_header = 'BookMe'
admin.site.index_title = 'BookMe Dashboard'
admin.site.site_title = 'BookMe Dashboard'

urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/', include('authentication.urls')),
    path('barber/', include('barber.urls')),
    path('customer/', include('customer.urls')),
    path('', include('django_prometheus.urls')),
]

# Future reference, serving static files via web server:
# # https://stackoverflow.com/questions/7241688/django-admin-css-missing/11299269.

# from django.conf.urls.static import static -> This helper function works only in debug mode
# and only if the given prefix is local (e.g. /static/) and not a URL (e.g. http://static.example.com/).
# You got stucked for a few hours because of this one time...
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)  # type: ignore
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)  # type: ignore
