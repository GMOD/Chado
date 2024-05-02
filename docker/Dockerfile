FROM ubuntu:24.04

ARG CHADO_VERSION='1.31'
ARG PGSQL_VERSION='16'

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

RUN  apt-get install -y postgresql-common \
   && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y \
   && apt-get install -y postgresql-${PGSQL_VERSION}

RUN cd /usr/local \
   && wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/10.12.0/flyway-commandline-10.12.0-linux-x64.tar.gz | tar xvz \
   && ln -s `pwd`/flyway-10.12.0/flyway /usr/local/bin

COPY . /Chado

RUN /etc/init.d/postgresql start \
   && su -c "createdb chado" - postgres \
   && su -c "psql chado < /Chado/schemas/${CHADO_VERSION}/default_schema.sql" - postgres \
   && su -c "psql -c \"ALTER USER postgres PASSWORD 'chadotest';\"" - postgres \
   && /etc/init.d/postgresql stop;

WORKDIR /Chado/docker
RUN cp flyway.toml /root/flyway.toml \
   && cp entrypoint.sh /usr/bin/entrypoint.sh \
   && chmod +x /usr/bin/entrypoint.sh \
   && cp motd /etc/motd

WORKDIR /Chado

RUN echo '[ ! -z "$TERM" -a -r /etc/motd ] && cat /etc/issue && cat /etc/motd' >> /etc/bash.bashrc

ENTRYPOINT ["entrypoint.sh"]
