GTCTOP = GTC
CTGTOP = CTG
CSRTOP = CSR

GTC_SRCPATH = conv/gametochadx
CTG_SRCPATH = conv/chadxtogame
#UTL_SRCPATH = conv/util

CONVPATH = classes

GMOD_PATH = /users/smutniak/gmod/schema/XMLTools/GameChadoConv
GMODLOCAL_PATH = /users/smutniak/ChadoXML/GameChadoConv

#JAVAC	= /soft/java/bin/javac -d ${CONVPATH}
JAVAC	= javac -d ${CONVPATH}

%.class	: %.java
	${JAVAC} $<

all	:clean gtc ctg

clean	:
	rm -f ${CONVPATH}/*.class
	rm -f ${CONVPATH}/${GTC_SRCPATH}/*.class
	rm -f ${CONVPATH}/${CTG_SRCPATH}/*.class
	#rm -f ${CONVPATH}/${UTL_SRCPATH}/*.class

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
	cp -r ./${CTG_SRCPATH}/*.java ${GMOD_PATH}/${CTG_SRCPATH}
	cp -r ./${CTG_SRCPATH}/*.java ${GMOD_PATH}/${GTC_SRCPATH}
	cp -r ./CTG.java ${GMOD_PATH}/CTG.java
	cp -r ./GTC.java ${GMOD_PATH}/GTC.java
	cp -r ./makefile ${GMOD_PATH}/makefile
	#cp -r ./${UTL_SRCPATH}/*.java ${GMOD_PATH}/${UTL_SRCPATH}
	echo "now run update from " ${GMOD_PATH}

upgradelocal:
	cp -r ./${CTG_SRCPATH}/*.java ${GMODLOCAL_PATH}/${CTG_SRCPATH}
	cp -r ./${GTC_SRCPATH}/*.java ${GMODLOCAL_PATH}/${GTC_SRCPATH}
	cp -r ./CTG.java ${GMODLOCAL_PATH}/CTG.java
	cp -r ./GTC.java ${GMODLOCAL_PATH}/GTC.java
	cp -r ./makefile ${GMODLOCAL_PATH}/makefile
	#cp -r ./${UTL_SRCPATH}/*.java ${GMODLOCAL_PATH}/${UTL_SRCPATH}
	echo "now run make from " ${GMODLOCAL_PATH}

runjar	:
	jar -cvf ${GTCTOP}.jar -C ${CONVPATH} .


docs	:
	mkdir -p ./JDOC/
	javadoc -d ./JDOC/ \
	${GTCTOP}.java \
	${CTGTOP}.java 

