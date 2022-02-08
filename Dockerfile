FROM ubuntu:18.10
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



RUN cd / ; \
    git clone https://github.com/GMOD/Chado.git ; \
    cd Chado; \
    git checkout 1.4; \
    /etc/init.d/postgresql start; \
    su -c "createdb chado" - postgres; \
    su -c "psql chado < /Chado/chado/schemas/1.4/default_schema.sql" - postgres; \
    /etc/init.d/postgresql stop;
    
#ENTRYPOINT["sh","/entrypoint.sh"]
CMD ["/etc/init.d/postgresql", "start"]
