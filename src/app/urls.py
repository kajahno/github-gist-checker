"""
URL Configuration for app
"""
from django.urls import include, path
from rest_framework import routers
from api import views

router = routers.DefaultRouter()
router.register(r"github-users", views.GithubUserViewSet)
router.register(r"gists", views.GistViewSet, basename="gists")
router.register(r"last-added-gists", views.GistLastAddedViewSet)

urlpatterns = [
    path("", include(router.urls)),
]
