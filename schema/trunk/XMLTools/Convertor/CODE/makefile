GTCTOP = GTC
CTGTOP = CTG

GTC_SRCPATH = org/gmod/chado/gametochadx
CTG_SRCPATH = org/gmod/chado/chadxtogame

CONVPATH = classes


JAVAC	= javac -d ${CONVPATH}

%.class	: %.java
	${JAVAC} $<

all	:clean gtc ctg

clean	:
	rm -f ${CONVPATH}/*.class
	rm -f ${CONVPATH}/${GTC_SRCPATH}/*.class
	rm -f ${CONVPATH}/${CTG_SRCPATH}/*.class

gtc	:
	mkdir -p ${CONVPATH}
	${JAVAC} ${GTCTOP}.java

ctg	:
	mkdir -p ${CONVPATH}
	${JAVAC} ${CTGTOP}.java



runjar	:
	jar -cvf ${GTCTOP}.jar -C ${CONVPATH} .


docs	:
	mkdir -p ./JDOC/
	javadoc -d ./JDOC/ \
	${GTCTOP}.java \
	${GTC_SRCPATH}/*.java \
	${GTC_SRCPATH}/AlignTools/*.java \
	${GTC_SRCPATH}/DataModel/*.java \
	${GTC_SRCPATH}/GBFF/*.java \
	${GTC_SRCPATH}/GBXML/*.java \
	${GTC_SRCPATH}/IDBXML/*.java

codejar	:
	jar -cvf JAVASEAN_CODE.jar \
	makefile \
	LICENSE \
	ARTISTIC_LICENSE \
	${GTCTOP}.java \
	${GTC_SRCPATH}/*.java \
	${GTC_SRCPATH}/AlignTools/*.java \
	${GTC_SRCPATH}/DataModel/*.java \
	${GTC_SRCPATH}/GBFF/*.java \
	${GTC_SRCPATH}/GBXML/*.java \
	${GTC_SRCPATH}/IDBXML/*.java \
	${GTC_SRCPATH}/PROP/*.properties \
	./TXTDOC/* \
	mapfile-sample.rpt

codetar	:
	tar -cvf JAVASEAN_CODE.tar \
	makefile \
	LICENSE \
	ARTISTIC_LICENSE \
	${GTCTOP}.java \
	${GTC_SRCPATH}/*.java \
	${GTC_SRCPATH}/AlignTools/*.java \
	${GTC_SRCPATH}/DataModel/*.java \
	${GTC_SRCPATH}/GBFF/*.java \
	${GTC_SRCPATH}/GBXML/*.java \
	${GTC_SRCPATH}/IDBXML/*.java \
	${GTC_SRCPATH}/PROP/*.properties \
	./TXTDOC/* \
	mapfile-sample.rpt
