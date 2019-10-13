from rest_framework import serializers

from api.models import GithubUser, Gist


class GithubUserSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = GithubUser
        fields = "__all__"

class GistSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Gist
        fields = "__all__"
