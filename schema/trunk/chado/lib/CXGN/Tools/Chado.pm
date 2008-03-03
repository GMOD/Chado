package CXGN::Tools::Chado;

use strict;
use warnings;
use Carp;

=head1 NAME

CXGN::Tools::Chado - silly little functions for doing silly
little things with a Chado DB

=head1 SYNOPSIS

  use CXGN::Tools::Chado qw/feature_exists/;

  if( feature_exists('foofoofoo') {
     print "OMGROFLOLOLOL!  There's a feature in there called foofoofoo!  I can't believe it!\n";
  }

=head1 FUNCTIONS

All functions are @EXPORT_OK.

=cut

BEGIN { our @EXPORT_OK = qw/ feature_exists  / }
our @EXPORT_OK;
use base 'Exporter';


=head2 feature_exists

  Usage: feature_exists('some_feature_name');
  Desc : look to see whether a feature with the given name exists in our chado db
  Ret  : the feature's name if it is there, undef otherwise
  Args : a feature name, (optional) dbh to use
  Side Effects:  looks up things in the chado db
  Example:

=cut

sub feature_exists {
  my ($feature_name,$dbh) = @_;
  $dbh ||= _dbh();

  my ($cnt) = $dbh->selectrow_array('select count(*) from public.feature where name=?',undef,$feature_name);
  return $cnt > 0 ? 1 : undef;
}


sub _dbh {
  our $dbname ||= CXGN::DB::Connection->new({dbschema => 'public'});
}


=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###

