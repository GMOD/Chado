#!/bin/sh

if [ "x$GMOD_ROOT" = "x" ]; then
  if [ "x$ARGOS_ROOT" = "x" ]; then
    GMOD_ROOT=/bio/argos/gmod
  else
    GMOD_ROOT="$ARGOS_ROOT/gmod"
  fi
fi

find_MY_HOME()
{
  PRG="$0"
  while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
      PRG="$link"
    else
      PRG=`dirname "$PRG"`/"$link"
    fi
  done
  
  MY_HOME=`dirname "$PRG"`/..
  # make it fully qualified
  MY_HOME=`cd "$MY_HOME" && pwd`
  PRG="basename $0"
}

find_MY_HOME

perl -e'require "$MY_HOME/bin/gmod_config.pl"; GmodInstallForm::installForm();' \
  -- -quiet -inroot=$GMOD_ROOT -root=$MY_HOME $@
