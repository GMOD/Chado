#convert postgres to mysql create table files

all :: ./modules/audit/audit.mysql \
       ./modules/companalysis/companalysis.mysql \
       ./modules/cv/cv.mysql \
       ./modules/expression/expression.mysql \
       ./modules/general/general.mysql \
       ./modules/genetic/genetic.mysql \
       ./modules/map/map.mysql \
       ./modules/organism/organism.mysql \
       ./modules/pub/pub.mysql \
       ./modules/sequence/sequence.mysql \
       ./modules/www/www.mysql \
       cdbi

%.mysql: %.sql
	./bin/pg2my.pl $< > $@

cdbi:
	./bin/pg2cdbi.pl ./modules/*/*.sql > ./src/mysql/Chado/AutoDBI.pm
