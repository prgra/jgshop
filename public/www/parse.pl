#!/usr/bin/perl -w
use utf8;
use Data::Dumper;
use strict;
my $dir=$ARGV[0];
my @files = glob("$dir/*.html"); 
foreach my $FileName (@files){
open FILE,$FileName;
my @file =<FILE>;
close FILE;
my $sec='';
my $sub=0;
my %obj;
my $prod=0;
my $type='';
my @types;
my @prods;
foreach my $l (@file)
{
	if ($l=~/BEGIN DESC/) {$sec='descr'}
	if ($l=~/BEGIN SPECS/) {$sec='specs'}
	if ($l=~/Production Center/) {$sec='prod'}
	if ($l=~/<TD CLASS="statcat">Required Components:<\/TD>/) {$sec='req';$prod=0;}
	if ($l=~/END/) {$sec=''}
	if ($sec eq 'descr') {
		if ($l=~/<TD BGCOLOR="#444444"><B>.+<\/B><\/TD>/) {($obj{type})=$l=~/<TD BGCOLOR="#444444"><B>(.+)<\/B><\/TD>/ }
		if ($l=~/<TD BGCOLOR="#222222" ALIGN="LEFT"><FONT SIZE="-1">.+<\/FONT><BR>/) {($obj{descr})=$l=~/<TD BGCOLOR="#222222" ALIGN="LEFT"><FONT SIZE="-1">(.+)<\/FONT><BR>/ }
		if ($l=~/<TD BGCOLOR="#334466" COLSPAN="7"><FONT SIZE="\+1"><B>".+"<\/B>/) {($obj{station_name})=$l=~/<TD BGCOLOR="#334466" COLSPAN="7"><FONT SIZE="\+1"><B>"(.+)"<\/B>/ }
	}	
	if ($sec eq 'prod') {
		if ($l =~ /<A HREF="..\/stations\/.+.html">.+<\/A><BR>/) {

			($obj{"product centers"}{$prod})=$l=~/<A HREF="..\/stations\/.+.html">(.+)<\/A><BR>/;
			$prod++;
		}
		if ($l=~/<TR BGCOLOR="#000000" VALIGN="TOP" ALIGN="RIGHT">/) {$sec='specs'}
	}
	if ($sec eq 'specs') {
		if ($l =~/<IMG SRC=".+" ALT=".+"/) {my ($img,$produse)=$l=~/<IMG SRC=".+\/(.+\.gif)" ALT="(.+)" BORDER="0" ALIGN="MIDDLE">/; 

#		print "update items set img='$img' where name = '$produse';\n";
		my ($station)=$FileName=~/stations\/(\w+).html/;
		#print "insert into items_prods (item_id,station_id) values ((select id from items where name = '$produse'),(select id from stations where name='$obj{station_name}'));\n";
		}
		if ($l =~/<TR BGCOLOR="#000000" VALIGN="TOP" ALIGN="RIGHT">/) {$sub=1}
		if ($sub==1 and $l =~/<TD CLASS="statcat" WIDTH="300">.+:<\/TD>/) {($type)=$l=~/<TD CLASS="statcat" WIDTH="300"> (.+):<\/TD>/;
push @types,$type;
$sub=0;}
		if ($type ne '' and $l =~/<TD CLASS="statgood">.+<\/TD>/){($obj{specs}{$type})=$l=~/<TD CLASS="statgood">(.+)<\/TD>/;$type=''}
	}
	if ($sec eq 'req'){
		if ($l=~/ALT=".+" BORDER="0" ALIGN="MIDDLE"/) {($obj{contain}{$prod})=$l=~/ALT="(.+)" BORDER="0" ALIGN="MIDDLE"/;push @prods,$obj{contain}{$prod};$prod++;}
	}
}

#print Dumper(\%obj);
my ($gg)=$FileName=~/^(\w+)\/\w+\.html/;
foreach my $l (@types) {

$l=~s/'/\\'/g;
$obj{descr}=~s/'/\\'/g;
$obj{specs}{CodeName}=~s/Mk\. I/Mk\.I/;
#print "insert into specs (item_id,spec_id,value) values ((select id from items where name = '",$obj{specs}{CodeName},"' ),(select id from items_specs where type_id=(select id from items_types where name = '$ARGV[0]') and name='$l') ,'$obj{specs}{$l}');\n";
if ($l eq "CodeName") {print "update items set descr='$obj{descr}' where name='$obj{specs}{CodeName}';\n";}
}
foreach my $l (@prods) {

$l=~s/'/\\'/g;
$obj{specs}{CodeName}=~s/Mk\. I/Mk\.I/;
$l=~s/Mk\. I/Mk\.I/;
print "insert into items_contains (item_id,contain_id) values ((select id from items where name = '",$obj{specs}{CodeName},"' ),(select id from items where name='$l'));\n";
}

#$obj{descr}=~s/'/\\'/g;
#print "update stations set descr='$obj{descr}',type='$obj{type}' where name = '$obj{station_name}';\n";
#print Dumper(\%obj);
}
