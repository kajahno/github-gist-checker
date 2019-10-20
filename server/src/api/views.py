import datetime
import logging

from rest_framework import status, viewsets
from rest_framework.response import Response

from api.models import Gist, GithubUser
from api.serializers import GistSerializer, GithubUserSerializer

logger = logging.getLogger(__name__)


class GithubUserViewSet(viewsets.ModelViewSet):
    """
    Handle interactions with GithubUser
    """

    queryset = GithubUser.objects.all()
    serializer_class = GithubUserSerializer


class GistViewSet(viewsets.ModelViewSet):
    """
    Shows all gists
    """

    queryset = Gist.objects.all()
    serializer_class = GistSerializer


class GistLastAddedViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Shows only gists for a user that are more recent than the last visited time.
    The Github username is specified as query param:

        /?github_user=[the github user]

    """

    queryset = Gist.objects.all()

    serializer_class = GistSerializer

    def list(self, request, Format=None):
        github_user = (
            request.query_params["github_user"]
            if "github_user" in request.query_params
            else None
        )

        if not github_user:
            msg = {"github_user": "Param required and not present"}
            logger.error(msg)
            return Response(msg, status=status.HTTP_400_BAD_REQUEST)

        try:
            github_user_db = GithubUser.objects.get(username=github_user)
        except GithubUser.DoesNotExist:
            msg = {"github_user": "'{}' Not found in database".format(github_user)}
            logger.error(msg)
            return Response(msg, status=status.HTTP_400_BAD_REQUEST)

        logging.info(
            "user: {}, found in database: {}".format(
                github_user, "true" if github_user_db else "false"
            )
        )

        queryset = None
        if github_user_db.last_visit:
            queryset = Gist.objects.filter(github_user__username=github_user).filter(
                created__gte=github_user_db.last_visit
            )
        else:
            queryset = Gist.objects.filter(github_user__username=github_user)

        logging.info(
            "user: {}, number of retrieved gists with date greater than {}: {}".format(
                github_user, github_user_db.last_visit, len(queryset)
            )
        )

        if len(queryset):
            last_visit = datetime.datetime.now()
            logging.info(
                "user: {}, updating last visit to {}".format(
                    github_user, last_visit.isoformat()
                )
            )
            github_user_db.last_visit = last_visit
            github_user_db.save()

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
