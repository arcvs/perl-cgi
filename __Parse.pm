package __Parse;

use strict;

my $cfg;

BEGIN {

	$cfg = __Config::new;
	
	$SIG{__WARN__} = sub {
	
		#warn shift;
		if ($cfg->{'debug_mode'}) {
		
			die shift;
		}
	};
	
	$SIG{__DIE__} = sub {
	
		if (!$cfg->{'debug_mode'}) {
		
			my $domen = $ENV{'SERVER_NAME'};
			
			print "Location: http://$domen/error/index/\r\n\r\n";
			
		} else {
				
			print "Content-type: text/html;charset=UTF-8\r\n\r\n"; 
			print '<pre>'.shift.'</pre>';
			exit(1);
		}
	};
}

#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
#print '<pre>'.(Dumper %{$self->{'ENV'}}).'</pre>';


sub new {

	my $self = shift;
	
	my $in 	 = $self->{'IN'} 	= {};
	my $cfg  = $self->{'CONF'} 	= __Config::new($ENV{'SERVER_NAME'});
	
	my @lcp = split('\?', $ENV{'REQUEST_URI'} ); # Language Controller Page
	
	my @url	= split('\/', substr ($lcp[0],1) );
	
	my $language 		= shift @url if exists $url[0] && exists $cfg->{'language'}->{$url[0]};
	my $controller	= shift @url || $self->{'NAME_CONTROLLER'};
	my $page				= shift @url || 'index';

	#$in->{'ENV'}			= 	{%ENV};

	$in->{'ctrl'}	=	$in->{'controller'}	=	$controller || undef; #? alias
	$in->{'page'} =	$page || undef;
	$in->{'lang'} = $in->{'language'} =	$language || $in->{'get_cookies'}{'local'} || local_language( $cfg ); #? alias
	
	if ($ENV{'HTTP_REFERER'}) {

		my @http_referer =	split('\?', substr ($ENV{'HTTP_REFERER'},1) );
		$in->{'referer_params'}	= {map {_parseKeyValueQuery($_)} split('&', $http_referer[1]||'')};
	}

	$in->{'GET'}	=	{map {_parseKeyValueQuery($_)} split('&', $ENV{'QUERY_STRING'})};
	$in->{'POST'}	=	form_data('POST')	|| undef;
	
	$in->{'get_cookies'}	= &get_cookies 				|| undef;
	$in->{'method'}				=	&method_name				|| undef;
	$in->{'multipart'}		=	&multipart 					|| undef;
	$in->{'server_name'}	= $ENV{'SERVER_NAME'};
	$in->{'ip_address'}		= &ip_address;
	return 1;
}
#=======================================================================

sub _parseKeyValueQuery {
	my @kv = split ('=', lc shift);
	return $kv[0] => uri_decoding($kv[1]);
}
#=======================================================================

sub method_name {

	return uc $ENV{ 'REQUEST_METHOD' };
}
#=======================================================================

sub form_data {

	my $query;

	use strict 'refs';

	if (&method_name eq 'GET') {

		#$query = $ENV{ 'REQUEST_URI' };
		#$query = $ENV{ 'QUERY_STRING' };
		
		#return handling( $query );

	}
	elsif (&method_name eq 'POST'
			and $ENV{ 'CONTENT_LENGTH' } != 0
			and $ENV{ 'CONTENT_TYPE' } !~ m/^multipart/ ) {

		sysread STDIN, $query, $ENV{ 'CONTENT_LENGTH' };
		
		return handling( $query );
	}
}
#=======================================================================

sub handling
	{
	#return shift;
	
	no warnings;
	
	my $hash = {};
	my @param;
	my $str = shift;

	# if ( $ENV{'REQUEST_METHOD'} eq 'POST') {

	foreach( split /&/, $str ) {
	# foreach( split /&/, shift ) {

		@param = split '=', $_;
		$hash->{ $param[0] } = uri_decoding($param[1]);
	}

	return $hash;
}
#=======================================================================

sub multipart {

	return 0 unless ( exists $ENV{ 'CONTENT_TYPE' }
		and $ENV{ 'CONTENT_TYPE' } =~ m/^multipart/ );
		
	return 1;

	binmode STDIN;

=INFO sysread

суть в том что при данном способе чтения потока
данные большого объема не буферизируются,
по этому их нужно считывать кусками. Для этого
как вариант необъходимо всю необходимую длинну
потока $ENV{ CONTENT_LENGTH } разбить на равные
малые участки потока. И каждый раз считывая
дописывать их в файл

$ENV{ CONTENT_LENGTH } делим примерно на 50 кб
плюс остаток и за каждую итерацию производим
дозапись в файл

open FILE > file/name;

binmode OUT;

for ( $ENV{ CONTENT_LENGTH } / 512 byte ) {

sysread STDIN, $stream, 512, (с того места где остановились) ;

print FILE $stream;

}

close FILE;

=cut

	read STDIN, my $query, $ENV{ CONTENT_LENGTH };

	return $query;
}
#=======================================================================

# Кодирует и декодирует не английские сиволы согласно utf8

sub uri_encoding {

	my $str = shift;
	$str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	return $str;
}

sub uri_decoding {

	my $str = shift || '';
	$str =~ s/[+]/ /g;
	$str =~ s/%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	return $str;
}

#=======================================================================

sub ip_address {

	my $ip_user;
	my $ip_proxy;

	if ( defined( $ENV{ 'HTTP_X_FORWARDER_FOR' } ) ) {

		$ip_user = $ENV{ 'HTTP_X_FORWARDER_FOR' };
		$ip_proxy = $ENV{ 'REMOTE_ADDR' };
	} else {
		$ip_user = $ENV{ 'REMOTE_ADDR' };
		$ip_proxy = 0;
	}
	return $ip_user || '127.0.0.0';
}
#=======================================================================

sub get_cookies {

	my $hash_cook = undef;

	if ( defined($ENV{ HTTP_COOKIE }) ) {

		my @cookies = split '; ', $ENV{ HTTP_COOKIE };
		my @value;

		for ( @cookies ) {
			@value = split '=', $_;
			$hash_cook->{ $value[0] } = $value[1];
		}

		return $hash_cook;
	}

	$hash_cook->{'ID'} = 0;

	return $hash_cook;
}
#=======================================================================

sub local_language {
	
	my $cfg = shift;

	my ($env, $lang_hash ) = ( $ENV{ HTTP_ACCEPT_LANGUAGE }, {} );

	$env =~ s/([\w-]{1,8})(?:;q=([\d\.]{1,4}))?/$lang_hash->{$2||''}=$1/ge;

	my @lang = split '-', $lang_hash->{''};

	if ( $cfg->{'language'}->{ $lang[0] } ) {

		return $lang[0];
	}
	else {

		while( my( $key, $values ) = each ( @{$cfg->{'language'}} ) ) {

			for ( @$values ) {
			
				return $key if ($_ eq $lang[0]);
			}
		}
	}

	return $cfg->{'diff_language'};
}
#=======================================================================
1;
