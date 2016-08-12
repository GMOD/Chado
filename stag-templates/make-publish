PUBTMPLDIR = /usr/local/share/bioconf/templates
TEMPLATEBINDIR = /usr/local/bin/stagbin

all: publish-templates executables

publish-templates:
	cp *.stg $(PUBTMPLDIR)

executables:
	find . -name "*stg" -exec stag-template2bin.pl -b $(TEMPLATEBINDIR) {} \;
