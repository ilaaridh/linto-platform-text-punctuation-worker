FROM python:3.8
LABEL maintainer="stanfous@linagora.com, rbaraglia@linagora.com"
ENV PYTHONUNBUFFERED TRUE

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    g++ \
    openjdk-11-jre-headless \
    curl \
    wget

# Rust compiler for tokenizers
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src/app

# Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY docker-entrypoint.sh wait-for-it.sh ./

# Supervisor
COPY supervisor /usr/src/app/supervisor
RUN mkdir -p /var/log/supervisor/

COPY punctuationworker /usr/src/app/punctuationworker
ENV PYTHONPATH="${PYTHONPATH}:/usr/src/app/punctuationworker"

COPY config.properties /usr/src/app/config.properties
RUN mkdir /usr/src/app/model-store
RUN mkdir -p /usr/src/app/tmp

HEALTHCHECK CMD curl http://localhost:8080/ping 

EXPOSE 8080 8081 8082 7070 7071

ENV TEMP=/usr/src/app/tmp
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["serve"]
