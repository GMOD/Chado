# HTML, PDF etc generated for asciidoc file using asciidoc.py
#
# See: http://www.methods.co.nz/asciidoc/

# there are two options for html; plain, and with CSS embedded
#
####HTML_BACKEND = html
HTML_BACKEND = css-embedded

%.html: %.asc
	asciidoc.py -b $(HTML_BACKEND) $<

# docbook xml format can be converted to pdf, rtf, ps, ...
%.xml: %.asc
	asciidoc.py -b docbook $<
.PRECIOUS: %.xml

# for this part you need xsltproc
ASCIIDOC_HOME = $(HOME)/asciidoc

# generate xsl formatting objects
%.fo: %.xml
	xsltproc $(ASCIIDOC_HOME)/doc/fo.xsl $< > $@
.PRECIOUS: %.fo

# you need apache fop for this
%.pdf: %.fo
	$(FOP_HOME)/fop.sh $< $@

#DSL_RTF = /sw/share/sgml/dsssl/docbook-dsssl-ldp/ldp.dsl#print
#%.rtf: %.xml
#	openjade -t rtf -d $(DSL_RTF) $<
