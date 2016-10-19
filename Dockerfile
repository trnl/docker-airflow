# VERSION 1.7.0
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow
# SOURCE: https://github.com/puckel/docker-airflow

FROM debian:jessie
MAINTAINER Puckel_

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux
ENV AIRFLOW_REPO git+ssh://git@github.com/LibertyGlobal/airflow.git
ENV AIRFLOW_BRANCH 1.7.1.3_dev
ENV AIRFLOW_HOME /usr/local/airflow

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Copy ssh key
ADD id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

# Copy ssh config
ADD ssh-config /root/.ssh/config

# Install packages
RUN set -ex \
    && buildDeps=' \
        python-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
    ' \
    && echo "deb http://http.debian.net/debian jessie-backports main" >/etc/apt/sources.list.d/backports.list \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        python-pip \
        apt-utils \
        curl \
        netcat \
        locales \
        ffmpeg \
        git \
        libmysqlclient-dev \
        mediainfo \
        smbclient \
        ssh \
    && apt-get install -yqq -t jessie-backports python-requests \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install Cython \
    && pip install pytz==2015.7 \
    && pip install pycparser==2.13 \
    && pip install cryptography \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install pymediainfo==2.1.4 \
    && pip install pysftp==0.2.8 \
    && pip install pysmb==1.1.18 \
    && pip install PySmbClient==0.1.3 \
    && pip install suds-jurko==0.6 \
    && pip install untangle==1.1.0 \
    && pip install ${AIRFLOW_REPO}@${AIRFLOW_BRANCH}#egg=airflow \
    && pip install ${AIRFLOW_REPO}@${AIRFLOW_BRANCH}#egg=airflow[celery] \
    && pip install ${AIRFLOW_REPO}@${AIRFLOW_BRANCH}#egg=airflow[mysql] \
    && apt-get remove --purge -yqq $buildDeps \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

ADD script/entrypoint.sh ${AIRFLOW_HOME}/entrypoint.sh
ADD config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME} && chmod +x ${AIRFLOW_HOME}/entrypoint.sh

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["./entrypoint.sh"]
