"""
    Command that polls for all gists of all github users in the databse
"""
import logging
from typing import List

import requests
from django.core.management.base import BaseCommand

from api.models import Gist, GithubUser

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "updates the internal gists list for the github users in the database"

    def handle(self, *args, **options):

        github_users = GithubUser.objects.all()
        print("finding gists updates for {} users".format(len(github_users)))

        for user in github_users:
            user_gists_insert_list = self.get_gists_for_github_user(user)
            if user_gists_insert_list:
                self.insert_gists_list_for_user_on_db(user, user_gists_insert_list)

    def get_gists_for_github_user(self, user: GithubUser) -> List[Gist]:

        username = user.username
        url = "https://api.github.com/users/{}/gists".format(username)
        print("checking gist updates on endpoint: {}".format(url))
        headers = {"Content-Type": "application/json"}
        response = requests.get(url, headers)

        if response.status_code != 200:
            print("error receiving response: {}".format(response.text))
            return

        json_data = response.json()
        num_gists = len(json_data)
        if not num_gists:
            print("for user '{}' there are no gists available".format(username))
            return

        print(
            "for user '{}' found a total of '{}' gists. Filtering that output...".format(
                username, len(json_data)
            )
        )
        gists_insert_list: List[Gist] = []
        for raw_gist in json_data:
            gist = self.build_gist_from_json(user, raw_gist)
            if gist:
                gists_insert_list += [gist]

        return gists_insert_list

    def build_gist_from_json(self, user: GithubUser, json_data: dict) -> Gist:
        """
        Builds a gist from the API json data, *if* it is not in the db already (using the gist_id)
        :param user:
        :param json_data:
        :return:
        """
        url = json_data["url"]
        gist_id = json_data["id"]
        created = json_data["created_at"]
        updated = json_data["updated_at"]
        description = json_data["description"]
        comments = json_data["comments"]
        comments_url = json_data["comments_url"]

        # check if gist in the database
        try:
            Gist.objects.get(gist_id=gist_id)
            return
        except Exception as e:
            print("gist with id {} does not exist. Message: {}".format(gist_id, str(e)))

        gist = Gist(
            url=url,
            gist_id=gist_id,
            created=created,
            updated=updated,
            description=description,
            comments=comments,
            comments_url=comments_url,
            github_user=user,
        )

        return gist

    def insert_gists_list_for_user_on_db(self, user: GithubUser, gists: List[Gist]):
        print("for user '{}' will insert/update {} gists".format(user, len(gists)))

        try:
            Gist.objects.bulk_create(gists)
            print("{} entries persisted in the database".format(len(gists)))
        except Exception as e:
            print("could not insert gists. Message: {}".format(str(e)))
