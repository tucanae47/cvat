# Copyright (C) 2018 Intel Corporation
#
# SPDX-License-Identifier: MIT

from .base import *

TIME_ZONE = "UTC"
DEBUG = False

INSTALLED_APPS += ["mod_wsgi.server"]

for key in RQ_QUEUES:
    RQ_QUEUES[key]["HOST"] = os.getenv("REDIS_HOST")

CACHEOPS_REDIS["host"] = os.getenv("REDIS_HOST")

# Django-sendfile:
# https://github.com/johnsensible/django-sendfile
SENDFILE_BACKEND = "sendfile.backends.xsendfile"

# Database
# https://docs.djangoproject.com/en/2.0/ref/settings/#databases


DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.mysql",
        "HOST": os.getenv("DB_HOST"),
        "NAME": os.getenv("DB_NAME"),
        "USER": os.getenv("DB_USER"),
        "PASSWORD": os.getenv("DB_PASSWORD"),
    }
}
