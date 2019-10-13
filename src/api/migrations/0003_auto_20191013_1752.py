# Generated by Django 2.2.6 on 2019-10-13 17:52

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [("api", "0002_auto_20191013_1741")]

    operations = [
        migrations.AlterModelOptions(
            name="siteactivity", options={"ordering": ["last_visit"]}
        ),
        migrations.AddField(
            model_name="siteactivity",
            name="id",
            field=models.AutoField(
                auto_created=True,
                default=None,
                primary_key=True,
                serialize=False,
                verbose_name="ID",
            ),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name="siteactivity",
            name="last_visit",
            field=models.DateTimeField(blank=True),
        ),
    ]
