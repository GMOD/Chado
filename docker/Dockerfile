FROM ubuntu:20.04
MAINTAINER Scott Cain <scott.cain@wormbase.org>

RUN apt-get update

#for some reason, this has to be installed by itself
RUN apt-get install -y tzdata

RUN apt-get install -y apt-utils

RUN apt-get install -y wget \
                       unzip \
                       git \
                       make \
                       gcc \
                       vim \
                       uuid-dev

RUN apt-get install -y postgresql-all

RUN cd /usr/local \
   && wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/8.5.2/flyway-commandline-8.5.2-linux-x64.tar.gz | tar xvz \
   && ln -s `pwd`/flyway-8.5.2/flyway /usr/local/bin

ARG CHADO_BRANCH=${CHADO_BRANCH}
ARG CHADO_VERSION=${CHADO_VERSION}

RUN cd / \
   && git clone https://github.com/GMOD/Chado.git  \
   && cd Chado \
   && git checkout ${CHADO_BRANCH}
   
RUN /etc/init.d/postgresql start \
   && su -c "createdb chado" - postgres \
   && su -c "psql chado < /Chado/chado/schemas/${CHADO_VERSION}/default_schema.sql" - postgres \
   && su - postgres \
   && psql -c "ALTER USER postgres PASSWORD 'chad0$test';" \
   && exit \
   && /etc/init.d/postgresql stop;

ADD flyway.conf flyway.conf

#ENTRYPOINT["sh","/entrypoint.sh"]
CMD ["/etc/init.d/postgresql", "start"]
