#!/bin/csh
# chado2acode.sh

if ( $#argv < 2 ) then
echo "Convert chado.xml(.gz|bz2) files to flybase acode using perl ChadoSax"
echo "Usage: $0 out.acode in.xml(s) [-debug] "
exit 1
endif

## need current XML/Parser/PerlSAX
setenv PERL5LIB "/bio/biodb/common/perl/lib:/bio/biodb/common/system-local/perl/lib:${PERL5LIB}"

set outf=$1; shift 
if ( -f $outf ) then
echo "output $outf exists; wont overwrite - please remove"
exit 1
endif

if ( -d "./ChadoSax/src" ) then
else
echo "need ChadoSax/src library"
exit 1
endif

touch $outf

# new options ToAcode::acode -debug -index -featfile=f -outfile=o
foreach xml ( $* )
perl -I./ChadoSax/src -M'org::gmod::chado::ix::ToAcode' -e 'acode;' -- \
 -feat=$outf.feats $xml  >> $outf
end

perl -I./ChadoSax/src -M'org::gmod::chado::ix::ToAcode' -e 'acodeindex;' -- $outf


#while ($1)
# perl ... $1
# shift
# end