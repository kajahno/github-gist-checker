from rest_framework import viewsets, status
from rest_framework.response import Response
import datetime

from api.models import GithubUser, Gist
from api.serializers import GithubUserSerializer, GistSerializer

import logging
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
        github_user = request.query_params['github_user'] if 'github_user' in request.query_params else None

        if not github_user:
            msg = {
                "github_user": "Param required and not present"
            }
            logger.error(msg)
            return Response(msg, status=status.HTTP_400_BAD_REQUEST)

        github_user_db = GithubUser.objects.get(username=github_user)
        logging.info("user: {}, found in database: {}".format(github_user, "true" if github_user_db else "false"))

        queryset = Gist.objects.filter(github_user__username=github_user).filter(created__gte=github_user_db.last_visit)
        logging.info("user: {}, number of retrieved gists with date greater than {}: {}".format(github_user, github_user_db.last_visit, len(queryset)))

        if len(queryset):
            last_visit = datetime.datetime.now()
            logging.info("user: {}, updating last visit to {}".format(github_user, last_visit.isoformat()))
            github_user_db.last_visit = last_visit
            github_user_db.save()

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

