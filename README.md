# Linto-platform-text-punctuation-worker

This service is an automatic punctuation restoration system for the French language. It is used to output our automatic speech transcription worker.

Automatic Speech Recognition (ASR) is the task of recognition and translation of spoken language into text. The resulting output is a sequence of words without punctuation or capitalization. Therefore, the goal of this worker is to restore punctuation only from the text, so that the output is more readable. 

We have done fine-tuning on French implementation of BERT, CamemBERT (https://arxiv.org/abs/1911.03894). We added a linear layer on top of the hidden-states output to predict a punctuation character (or not) after each token. It's a Named-Entity-Recognition (NER) task.

We trained the model using PyTorch.
The inference service is launched using TorchServe (https://pytorch.org/serve/) which is an easy and flexible tool to serve PyTorch models.

# Develop

## Installation

### Packaged in Docker
To start the punctuation restoration service on your local machine, you first need to download the source code, as follows:

```bash
git clone https://github.com/linto-ai/linto-platform-text-punctuation-worker

Then, to build the docker image, execute:

```bash
docker build -t lintoai/linto-platform-text-punctuation-worker:latest .
```

Or by docker-compose, by using:
```bash
docker-compose build
```


Or, download the pre-built image from docker-hub:

```bash
docker pull lintoai/linto-platform-text-punctuation-worker:latest
```

NB: You must install docker and docker-compose on your machine. 

## Configuration

Our service needs the punctuation model to run, it's a MAR file (compressed format) containing the architecture and the trained weights of the model, some configuration files (hyperparameters, assets), the name of the model and its version, and inference handlers (that enable to run inference out of the box without having to modify the code). 

The name of the model is bert_punc, and the current version is 1.0.

1- Download the latest version of the model (MAR file) here.

```bash
wget https://dl.linto.ai/downloads/model-distribution/punctuation_models/fr-FR/bert_punc.mar
```

2- Configure the environment file `.env` included in this repository

    MODEL_PATH=/path_to_mar_model
    LOGS_PATH=/path_to_logs_folder
    CACHE_PATH=/path_to_cache_folder

NB: When you run the service, some files are loaded in the cache. These files are quite big : around 300Mo. When you stop the container, these files are removed, so you need to create it each time you run the container, and depending on your Internet connexion, it could last some long seconds or minutes. So we decided to store these files permanently in the {CACHE_PATH} : there are loaded one time, and when you kill and restart your container, the service won't download it on the Internet.

3- (Optionnal) Connect to the service broker

You can connect the punctuation service to an exiting service broker such as Redis by filling:

    SERVICES_BROKER=redis://your-broker-address:broker-port

If the broker is available, it will spawn a worker listenning for ```punctuation_task``` on the dedicated queue ```punctuation```.


## Execute

In order to run the service, you only have to execute:

```bash
cd linto-platform-text-punctuation-worker
docker-compose up
```

### APIs

Here we describe the main APIs for inference. To check for other functionalities like models management and metrics, check the REST API documentation of TorchServe : https://pytorch.org/serve/rest_api.html

Port 8080 is for inference, port 8081 for models management and 8082 for metrics.

#### POST /predictions/bert_punc

 Run inference to get punctuated text

#### curl Example

```bash
curl -X POST localhost:8080/predictions/bert_punc -T <text file>
```

#### Using redis and celery
If you have declared a service broker you can call the task:

```python
def punctuation_task(self, text : Union[str, list], spk_sep: str = None)
```

Exemple using celery: 

```python
from celery import Celery
celery = Celery("celery_client")
broker_url = "redis://my-broker:6379"
celery.conf.broker_url = "{}/0".format(broker_url)
celery.conf.result_backend = "{}/1".format(broker_url)
taskid = celery.send_task(name="punctuation_task", queue="punctuation", args=["hello i want this text with punctuation"])
result = taskid.get()
print(result)
```

```bash
>> Hello, I want this text, with punctuation.
```
