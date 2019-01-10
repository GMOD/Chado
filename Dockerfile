FROM postgres:9.5

ENV DEBIAN_FRONTEND=noninteractive \
    POSTGRES_PASSWORD=postgres \
    PGDATA=/var/lib/postgresql/data/
    
COPY chado/schemas/1.31/default_schema.sql /docker-entrypoint-initdb.d/
