GTCTOP = GTC
CTGTOP = CTG
CSRTOP = CSR

#GTC_SRCPATH = org/gmod/chado/gametochadx
#CTG_SRCPATH = org/gmod/chado/chadxtogame

GTC_SRCPATH = conv/gametochadx
CTG_SRCPATH = conv/chadxtogame

CONVPATH = classes

#GMOD_PATH = /users/smutniak/gmodtest
GMOD_PATH = /users/smutniak/gmod/schema/XMLTools/GameChadoConv

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


upgrade:
	cp -r ./conv/chadxtogame/*.java ${GMOD_PATH}/conv/chadxtogame
	cp -r ./conv/gametochadx/*.java ${GMOD_PATH}/conv/gametochadx
	cp -r ./CTG.java ${GMOD_PATH}/CTG.java
	cp -r ./GTC.java ${GMOD_PATH}/GTC.java
	cp -r ./makefile ${GMOD_PATH}/makefile
	echo "now run update from /users/smutniak/gmod/schema/XMLTools/"

runjar	:
	jar -cvf ${GTCTOP}.jar -C ${CONVPATH} .


docs	:
	mkdir -p ./JDOC/
	javadoc -d ./JDOC/ \
	${GTCTOP}.java \
	${CTGTOP}.java 

