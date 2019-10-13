from django.db import models

class GithubUser(models.Model):
    created = models.DateTimeField(auto_now_add=True)
    username = models.CharField(max_length=100, blank=False)
    last_visit = models.DateTimeField(null=True)

    class Meta:
        ordering = ['created']

    def __str__(self):
        return self.username

class Gist(models.Model):
    url = models.URLField()
    gist_id = models.CharField(max_length=300, unique=True)
    created = models.DateTimeField()
    updated = models.DateTimeField()
    description = models.CharField(max_length=500)
    comments = models.IntegerField()
    comments_url = models.URLField()

    github_user = models.ForeignKey(GithubUser, on_delete=models.CASCADE)

    class Meta:
        ordering = ['created']

    def __str__(self):
        return "{}, github_user={}".format(self.gist_id, self.github_user.username)
