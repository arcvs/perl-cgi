package __Base;

use strict;

use DBI;
use __Config;

my $cfg = __Config::new;

#======================================= DATABASE CONNECT DISCONNECT QUERY
my 	$dbh = DBI->connect(

		$cfg->{'dbi_conf'},
		$cfg->{'mysqluser'},
		$cfg->{'mysqlpass'}

	) or die $DBI::errstr;

$dbh->do("SET NAMES 'utf8'");
$dbh->do("SET CHARACTER SET 'utf8'");
$dbh->do("SET SESSION collation_connection = 'utf8_unicode_ci'");
#===================================================================== END

sub new {

	my $self = shift;
	
	$self->{'QR'} = \&getting_setting_data;
}

sub getting_setting_data {
	
	my $type = shift;
	my $query = shift;
	my @params = @_;
	
	# Подготавливает запрос
	$dbh->quote( $query );
	
	# Подготавливает и выполняет запрос
	my $sth = $dbh->prepare( $query );
	
	# Выполняет запрос
	my $res = $sth->execute( @params ) or die $dbh->errstr;

	# $dbh->disconnect;
	
	
	if ($type eq '%') {
	
		return $sth->fetchrow_hashref();
		
	} elsif ($type eq '@') {
	
		return $sth->fetchall_arrayref();
		
	} elsif ($type eq '$') {
		
		return $sth->fetchrow_array();
		
	} elsif ($type eq '$$') {
	
		return $sth->fetchrow_arrayref();
	} else {
	
		return $res;
	}
	
	#$sth->finish;
	
	return 0;
}

sub dc {
	return $dbh->disconnect;
}
1;