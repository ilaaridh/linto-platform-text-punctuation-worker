#!/bin/bash
set -e

echo "RUNNING service"
supervisord -c /usr/src/app/supervisor/supervisor.conf

if [[ ! -z "$SERVICES_BROKER" ]]
then
    echo "Running celery worker"
    
    /usr/src/app/wait-for-it.sh $(echo $SERVICES_BROKER | cut -d'/' -f 3) --timeout=20 --strict -- echo " $REDIS_BROKER (Service Broker) is up"
    supervisorctl -c /usr/src/app/supervisor/supervisor.conf start punctuation_worker
fi

if [[ "$1" = "serve" ]]; 
then
    echo "Running Serving"
    shift 1
    torchserve --start --ncs --ts-config /usr/src/app/config.properties
else
    eval "$@"
    exit 0
fi

supervisorctl -c supervisor/supervisor.conf tail -f serving stderr
