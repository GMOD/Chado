#convert postgres to mysql create table files

all :: audit/audit.mysql \
       companalysis/companalysis.mysql \
       cv/cv.mysql \
       expression/expression.mysql \
       general/general.mysql \
       genetic/genetic.mysql \
       map/map.mysql \
       organism/organism.mysql \
       pub/pub.mysql \
       sequence/sequence.mysql \
       www/www.mysql

%.mysql: %.sql
	./bin/pg2my.pl $< > $@
