# Generated by Django 2.2.6 on 2019-10-13 18:12

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [("api", "0004_githubuser_last_visit")]

    operations = [
        migrations.AlterField(
            model_name="githubuser",
            name="last_visit",
            field=models.DateTimeField(null=True),
        )
    ]
