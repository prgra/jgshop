#
# (c) aef, 2012
#
use strict;

use utf8;

package Adb;
my $dsnFile = "dsn-config.pl";
unless( -f $dsnFile){
    $dsnFile = "dsn-config.pl";
}
our $ds=require $dsnFile;

our $debug :shared=0;
use Data::Dumper;
use DBI;

use POSIX qw(strftime);

BEGIN {
    use Exporter;
    our (@EXPORT,@ISA,@EXPORT_OK);
    @ISA = qw(Exporter);

    @EXPORT=qw(&debug &dbhClose &doQuery  &getDbh  &getFirstRow &doModify &getAll &getAllArray);
    @EXPORT_OK=@EXPORT;
}

#######################################################
sub debug(@){
    print STDERR @_ if $debug;
}
sub info(@){
    print getTime(),": ";
    print @_;
}
#######################################################
sub getDbh($){
    my $dsn=shift;
    return $dsn unless (ref($dsn) ne 'SCALAR');

    die "unknown datasource $dsn" unless(exists $ds->{$dsn});
    return  $ds->{$dsn}->{'dbh'} if(exists $ds->{$dsn}->{'dbh'});

    my $dbh;
    if ($ds->{$dsn}->{'connect'} !~ /mysql/){ $dbh = DBI->connect($ds->{$dsn}->{'connect'},
      $ds->{$dsn}->{'login'},
      $ds->{$dsn}->{'pass'}) or die "Can't open database";}
    else { $dbh = DBI->connect($ds->{$dsn}->{'connect'},
     $ds->{$dsn}->{'login'},
     $ds->{$dsn}->{'pass'},{
        RaiseError              => 1,
        AutoCommit              => 1,
        mysql_multi_statements  => 1,
        mysql_enable_utf8       => 1,
        mysql_init_command      => q{SET NAMES 'utf8';SET CHARACTER SET 'utf8'}
        }) or die "Can't open database";}
    
    #$dbh->{Debug} = 1;
    $dbh->{RaiseError} = 1;
#    $dbh->{AutoCommit} = 0;
if($ds->{$dsn}->{'connect'} =~ /mysql/ ){
	$dbh->do('SET NAMES utf8;');
    $dbh->{mysql_enable_utf8} = 1;
    $dbh->{mysql_auto_reconnect} = 1;

}
$ds->{$dsn}->{'dbh'}= $dbh;
return $dbh;
}
#######################################################
sub dbhClose(){
    my $aref;
    foreach $aref(values(%$ds)){
       $aref->{'dbh'}->disconnect() if exists $aref->{'dbh'};
   }
}
#######################################################
sub doModify($$@){
    my $dsn=shift;
    my $dbh = getDbh($dsn);
    my $query=shift;
    my $rc;
    my $sth = $dbh->prepare($query);
    #print STDERR "Modify query dsn=$dsn, q=$query !!";
    if ($sth){
      $sth -> execute(@_);
      $sth->finish;
  }
  return $rc;
}
#######################################################
sub doQuery($$&@){
    my $dsn=shift;
    my $dbh = getDbh($dsn);
    my $query=shift;
    my $handler = shift;
    #print STDERR "Execute query dsn=$dsn, q=$query !!";
    my $sth = $dbh->prepare($query);
    $sth -> execute(@_);
    while(my $a = $sth->fetchrow_hashref()) {
       &$handler($a);
   }
   $sth->finish;
}
#######################################################
sub getAll($$@){
    my $dsn=shift;
    my $query=shift;
    my @a;
    doQuery($dsn,$query,sub{
        push @a,$_[0];
        },@_);
    return \@a;
}


#######################################################
sub getAllArray($$@){
    my $dsn=shift;
    my $dbh = getDbh($dsn);
    my $query=shift;

    my $sth = $dbh->prepare($query);
    $sth -> execute(@_);
    my $names = $sth->{'NAME'};
    my $a = $sth->fetchall_arrayref(); 
    #unshift @$a, $names;
    $sth->finish;
    return {'names' => $names,"data" => $a };
}

#######################################################
sub getFirstRow($$@){
    my $dsn=shift;
    my $dbh = getDbh($dsn);
    my $query=shift;

    my $sth = $dbh->prepare($query);
    $sth -> execute(@_);
    my $a = $sth->fetchrow_hashref(); 
    $sth->finish;
    return $a;
}

1;

