import os
from celery import Celery

celery = Celery(__name__, include=['celery_int.punctuation_task'])
broker_url = os.environ.get("SERVICES_BROKER", "redis://localhost:6379")
celery.conf.broker_url = "{}/0".format(broker_url)
celery.conf.result_backend = "{}/1".format(broker_url)
celery.conf.update(
    result_expires=3600,
    task_acks_late=True,
    task_track_started = True)

# Queues
celery.conf.update(
    {'task_routes': {
        'punctuation_task' : {'queue': 'punctuation'},}
    }
)