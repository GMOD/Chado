package Chado::DBI;
use strict;
use base 'Class::DBI::Pg';

package GMOD::Chado::LoadDBI;
use strict;

sub init {
  my $self= shift;
  my @parts= qw(NAME HOST PORT USERNAME PASSWORD);
  my %vals = @_; # expect key => value hash of above parts 
  
  foreach my $part (@parts) {   # check %ENV  for missing parts
    next if ($vals{$part});  
    my $v= $ENV{'CHADO_DB_'.$part};
    $vals{$part}= $v if ($v);
    }

  my $dbname=  $vals{NAME} || 'chado_db';  # fallback 
  my $host  = ($vals{HOST} ? ";host=$vals{HOST}" : '');
  my $port  = ($vals{PORT} ? ";port=$vals{PORT}" : '');
  my $AutoCommit= $vals{AutoCommit} || 0;
  
  warn "GMOD::Chado::LoadDBI(dbi:Pg:dbname=$dbname$port$host,$vals{USERNAME},passwd)\n" 
    if $ENV{'DEBUG'};
    
  Chado::DBI->set_db(
  'Main',
  "dbi:Pg:dbname=$dbname$port$host", 
   $vals{USERNAME},  
   $vals{PASSWORD},
    {
      AutoCommit => $AutoCommit
    }
  );

  require Chado::AutoDBI; # now init database tables, etc.
}

  
1;

__END__

# From gmod-schema-admin@lists.sourceforge.net  Wed Dec  3 10:32:06 2003
# Subject: Re: [Gmod-schema] Re: RoadMap
# From: Scott Cain <cain@cshl.org>
# To: Lincoln Stein <lstein@cshl.org>
# Cc: stan letovsky <SLetovsky@aol.com>, alldev@morgan.harvard.edu,
#    "Owen R. White" <owhite@tigr.org>, angiuoli@tigr.org,
#    Allen Day <allenday@ucla.edu>, Hilmar Lapp <hlapp@gnf.org>,
#    "Ken Y. Clark" <kclark@cshl.org>,
#    gmod schema <gmod-schema@lists.sourceforge.net>
# Message-Id: <1070465481.1435.18.camel@localhost.localdomain>
# 
# Add to this list GMOD_PATH (ie, /usr/local/gmod).  (Thanks Don)
# 
# Also, I've added this information to the developers guide:
# 
#   http://www.gmod.org/developer_guide.shtml
# 
# Scott
# 
# On Tue, 2003-12-02 at 23:17, Scott Cain wrote:
# > Hello,
# > 
# > Below is the list of environment variables that will be used at the time
# > of chado installation and also sourced by admin accounts and at apache
# > start up.
# > 
# > CHADO_DB_NAME
# > CHADO_DB_USERNAME
# > CHADO_DB_PASSWORD
# > CHADO_DB_HOST
# > CHADO_DB_PORT
# > 
# > Nothing else strikes me as particularly necessary; are there any
# > suggestions for additions?
# > 
# > Thanks,
# > Scott

# From gmod-schema-admin@lists.sourceforge.net  Fri Feb 13 14:29:43 2004
# From: Allen Day <allenday@ucla.edu>
# 1       package Chado::DBI;
# 2       use strict;
# 3       use base 'Class::DBI::Pg';
# 4       
# 5       package Chado::LoadDBI;
# 6       use strict;
# 7       
# 8       BEGIN {
# 9       Chado::DBI->set_db('Main',
# 10        "dbi:Pg:dbname=$ENV{GMOD_DBNAME};port=5432;host=$ENV{GMOD_HOST}",
# 11        $ENV{GMOD_USER},
# 12        $ENV{GMOD_PASS},
# 13        {
# 14          AutoCommit => 0
# 15        }
# 16      );
# 17      }
# 18      
# 19      use Chado::AutoDBI;
# 20
# 21      1;

# package Chado::LoadDBI;
# 
# use strict;
# use base 'Class::DBI::Pg';
# # was this# use Chado::AutoDBI;  

# =head1 Chado::LoadDBI::init( %dbvalues)
# 
#   Initialize Chado::DBI, calling set_db with db values from init or ENV
# 
# =head1 Usage
# 
#     use GMOD::Config;  
#       # optional; loads file of conf/gmod.conf values to ENV
#     
#     use Chado::LoadDBI; 
#       # now waits for Chado::LoadDBI->init(%dbvals) call to open db 
#     
#     my %dbvals= map { $_ => '' } qw(NAME HOST PORT USERNAME PASSWORD);
# 
#     GetOptions(  
#       'dbname:s' => \$dbvals{NAME},
#       'name:s' => \$dbvals{NAME},
#       'host:s' => \$dbvals{HOST},
#       'port:s' => \$dbvals{PORT},
#       'username:s' => \$dbvals{USERNAME},
#       'password:s' => \$dbvals{PASSWORD},
#       @other_options,
#     );
#     
#       ## initialize database - checks both input parameters
#       ## and $ENV{ CHADO_DB_(NAME ... PASSWORD) }
#     Chado::LoadDBI->init( %dbvals);
#     
#     ## and use it
#    ($chado_organism) = Chado::Organism->search( common_name => lc('Human') );
# 
#   
# Also checks for $ENV{ CHADO_DB_(NAME ... PASSWORD) 
# 
# D. Gilbert, feb04 - changed fixed database values to read %ENV
# and call params: -dbname, -user, -password, -port, -host
# 
# =head1 SQL::Translator::ClassDBI.pm generator change
# 
#   -- flip inheritance so Mydb::DBI inherits from Mydb::LoadDBI 
#     This is really crux of problem. The common DBI database args that
#     the other DBI subclasses pass on have been swallowed from runtime use
#     by ClassDBI.pm's perl module generator.  
#     This is not good for many use cases:
#        (a) multiple passworded access to same database, e.g.
#            public readonly, private readonly, writeupdate (same db w/ multiple user/pass)
#        (b) distributed/load-balanced databases (same db w/ multiple host/port values)
#        (c) multiple dbs with same schema, software differ only by dbname, using
#           same perl library
# 
#   -- LoadDBI::init( %dbvalues ) now handles parameters and ENV values 
#     and requires AutoDBI
#  
#   -- AutoDBI.pm now looks like
#   
#     package Chado::DBI;
#     # Created by SQL::Translator::Producer::ClassDBI
#     
#     use strict;
#     use base 'Chado::LoadDBI';  ## change here
#     
#     # -------------------------------------------------------------------
#     package Chado::Tableinfo;
#     use base 'Chado::DBI';
#     use Class::DBI::Pager;
#     
#     Chado::Tableinfo->set_up_table('tableinfo');
#     ....
# 
# =cut
# 
# 
# =item
# 
#   ### original hard-coded values
#   Chado::DBI->set_db( 'Main', dbi:Pg:dbname=chado-test;port=7302;host=localhost", 
#     "chadouser", "",
#     {
#       AutoCommit => 0
#     }
#   );
# 
# =cut

# =item
# 
#   ## Option for init() with Argos system - check for more ENV keys
#   ## these are not needed really, just CHADO_DB_keys
#
#    
#   my @service_db= ('CHADO_DB'); # since this is Chado:: module
#   unshift(@service_db, $ENV{'GMOD_SERVICE'}.'_DB')  if (defined $ENV{'GMOD_SERVICE'}); 
#   unshift(@service_db, $ENV{'ARGOS_SERVICE'}.'_DB')  if (defined $ENV{'ARGOS_SERVICE'}); 
#       # check first service_db keys, default to chado_db =  flybase, eugenes, daphnia, etc.
#   foreach my $service_db (@service_db) {
#     foreach my $part (@parts) {
#       next if ($vals{$part});  
#       my $v= $ENV{$service_db.'_'.$part};
#       $vals{$part}= $v if ($v);
#       }
#     }
# 
# =cut

 
# =item
# 
#   #  # first check calling parameters --- 
#   #  # dont really need this; use simple case that @_ == hash of parts key => value
#   # my @vals = rearrange( \@parts, @_);
#   # my %vals= map { $parts[$_] => $vals[$_] || ''; } (0..$#parts);
#  ##warn "Chado::LoadDBI args=" . join(',', map { "$_=$vals{$_}" } keys %vals) if $DEBUG;
# 
# =cut
# 
# # scarfed from Ace.pm -- not needed
# sub rearrange {
#   my($order,@param) = @_;
#   return unless @param;
#   my %param;
# 
#   if (ref $param[0] eq 'HASH') {
#     %param = %{$param[0]};
#   } else {
#     #? why this; don't require -key => value when key => value is more general
#     # return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');
# 
#     my $i;
#     for ($i=0;$i<@param;$i+=2) {
#       $param[$i]=~s/^\-//;     # get rid of initial - if present
#       $param[$i]=~tr/a-z/A-Z/; # parameters are upper case
#     }
# 
#     %param = @param;                # convert into associative array
#   }
# 
#   my(@return_array);
# 
#   local($^W) = 0;
#   my($key)='';
#   foreach $key (@$order) {
#       my($value);
#       if (ref($key) eq 'ARRAY') {
#           foreach (@$key) {
#               last if defined($value);
#               $value = $param{$_};
#               delete $param{$_};
#           }
#       } else {
#           $value = $param{$key};
#           delete $param{$key};
#       }
#       push(@return_array,$value);
#   }
#   push (@return_array,\%param) if %param;
#   return @return_array;
# }
# 
