"""
URL Configuration for app
"""
from django.urls import include, path
from rest_framework import routers


router = routers.DefaultRouter()
# router.register(r"users", views.UserViewSet)

urlpatterns = [
    path("", include(router.urls)),
    # path("api-auth/", include("rest_framework.urls", namespace="rest_framework")),
    # path("admin/", admin.site.urls),
]
