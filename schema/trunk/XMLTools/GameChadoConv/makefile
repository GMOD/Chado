GTCTOP = GTC
CTGTOP = CTG
CSRTOP = CSR

#GTC_SRCPATH = org/gmod/chado/gametochadx
#CTG_SRCPATH = org/gmod/chado/chadxtogame

GTC_SRCPATH = conv/gametochadx
CTG_SRCPATH = conv/chadxtogame

CONVPATH = classes


#JAVAC	= /soft/java/bin/javac -d ${CONVPATH}
JAVAC	= javac -d ${CONVPATH}

%.class	: %.java
	${JAVAC} $<

all	:clean gtc ctg

clean	:
	rm -f ${CONVPATH}/*.class
	rm -f ${CONVPATH}/${GTC_SRCPATH}/*.class
	rm -f ${CONVPATH}/${CTG_SRCPATH}/*.class

csr	:clean
	mkdir -p ${CONVPATH}
	${JAVAC} ${CSRTOP}.java

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
	${CTGTOP}.java 

