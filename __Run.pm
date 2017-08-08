package __Run;

use strict;

use parent ('Exporter');
our @EXPORT;

use __Config;
use __Parse;
use __Base;
use __Access;

# $cross_ref = {} указатель на хэш, который является общим реестром входящих 
# и исходящих данных. 
# На основе cross_ref создаются функции и экспортируются в контроллеры

my $cross_ref = {};

keys (%$cross_ref) = 16;

{
	#$cross_ref->{'INFO'} 	= $cross_ref;
	
	$cross_ref->{'NAME_CONTROLLER'}	= caller;
	$cross_ref->{'MODE'}	= {};	# режим работы ядра
	$cross_ref->{'OUT'} 	= {};	# для сбора общих данных
	$cross_ref->{'CONF'} 	= {};
	$cross_ref->{'IN'} 		= {};	# входящие данные
	$cross_ref->{'QR'} 		= {}; # обработчик sql запросов 
	$cross_ref->{'USER'} 	= {};
	$cross_ref->{'START'} = \&content_printing; # обрабатывает контент по шаблону
	$cross_ref->{'ASSAY'} = \&argument_checking; # обработка маски для запросов
	$cross_ref->{'URL'} 	= \&set_get_url; # помощник формирования ссылок 
	$cross_ref->{'FIRST_BASE'} = {};
	
	no strict 'refs';	
	
	for my $key ( keys %$cross_ref ) {

		*{__PACKAGE__.'::'."$key"} = sub {return $cross_ref->{$key};};
		push @EXPORT, $key;
	}
}

#_Run::init('MODE' => 'anonymous');

sub init {

	$cross_ref->{'MODE'}{'PARSING_TPL'} = 1;
	
	$cross_ref->{'MODE'}{$_[0]} = $_[1] if exists $_[0];	

	__Parse::new( $cross_ref ) 	|| die "can`t parsing: $!";	
	__Base::new( $cross_ref )		|| die "can`t start query: $!";
	__Access::new( $cross_ref ) || die "can`t get access: $!";
	__Config::new( $cross_ref ) || die "can`t load config: $!";
}


# Форматированние заголовка по средствам параметров
# указанных в контроллере

#OUT->{'header'} = [
#	'Content-type' 	=> 	'text/html;charset=UTF-8',
#	'Cache-Control' => 	'no-cache'
#];
#OUT->{'status'} 	= '200';

sub _header {

	my $typeUploadPage = shift || '';

	if ( exists $cross_ref->{'OUT'}{'header'} ) {

		return	$cross_ref->{'OUT'}{'header'}[0].":".
				$cross_ref->{'OUT'}{'header'}[1]."\r\n\r\n";

	} elsif ( $typeUploadPage eq 'json' ) {

		return "Content-Type:application/json;charset=UTF-8\r\n\r\n";

	} else {
		return "Content-Type:text/html;charset=UTF-8\r\n\r\n";
	}
}

# Загрузка данных из контроллера по запрашиваемым
# индификаторам установленных в шаблоне

sub change {
		
	my $param = shift;
	my $param_extend = shift;
	
	if ($param eq 'Base') {
	
		return $cross_ref->{'OUT'}{$param_extend} 
			|| $cross_ref->{'FIRST_BASE'}{$param_extend} || '';
		
	} elsif ( ref $cross_ref->{'OUT'}{$param} eq 'HASH' ) {

		return $cross_ref->{'OUT'}{$param}->{$param_extend} || '';
		
	} elsif ( ref $cross_ref->{'OUT'}{$param} eq 'CODE' ) {

		return &{$cross_ref->{'OUT'}{$param}} || '';
		
	} else {
	
		$cross_ref->{'MODE'}{'PARSING_TPL'} = 0 if $param eq 'parsingoff';
		
		return $cross_ref->{'OUT'}{$param} || '';
	}
}

# Загрузка шаблона и подстановка в него содержимого OUT->{''} = $ || sub
# с последующей печатью в стандартный поток STDIN: START->();

sub content_printing {

	my $typeUploadPage = shift || '';
	
	print _header( $typeUploadPage );

	if ( $typeUploadPage eq 'json' ) {
	
		print $cross_ref->{'OUT'}{'json'} || '{"ok":"no_data"}';
		exit(1);
	}
	
	my $puth_home = $cross_ref->{'CONF'}{'puth_home'};
	my $file_name = $cross_ref->{'OUT'}{'template'} 
				|| $cross_ref->{'CONF'}{'index_tpl'};

	open (my $file_tpl, '<', $puth_home.$file_name)
			|| die "can`t open template file: ${puth_home}$file_name $!";

	$| = 1;
		
	while (<$file_tpl>) {

		if ($cross_ref->{'MODE'}{'PARSING_TPL'} && m/\*{3}\s/) {
			
			s/\*{3}\s([_a-z]+)\ ?([a-z]+)?/change($1,$2)/ie;
		}

		print $_;
	}
	
	close $file_tpl || die "can't close template file: $file_name $!";
	
	exit(1);
}


# Подготавливает адрес ссылки с схранением всех параметров запроса,
# при не необходимости изменяет или удаляет параметры

# TASK_1: сделать грамотное изменение контроллера, страницы и языка

sub set_get_url {

	no warnings;

	my $typeURL = ($_[0] eq 'referer_params') ? shift @_ : 'GET';
	my $noParam = ($_[0] eq 'no_params') ? shift @_ : undef;
	
	my (%params) = @_;
	
	my %paramsCommon;
	
	foreach my $substanceref ($$cross_ref{'IN'}{$typeURL}, \%params) {
		while (my ($k, $v) = each %$substanceref) {
			$paramsCommon{$k} = $v;
		}
	}
	
	my $lang = $cross_ref->{'IN'}{'lang'};
	my $ctrl = $cross_ref->{'IN'}{'ctrl'};
	my $page = $cross_ref->{'IN'}{'page'};
	
	my $hot_url;
	
	for my $key ( keys %paramsCommon) {
	
		$lang = $paramsCommon{$key}, next if $key eq 'lang';
		$ctrl = $paramsCommon{$key}, next if $key eq 'ctrl';
		$page = $paramsCommon{$key}, next if $key eq 'page';
		$hot_url .= $key.'='.$paramsCommon{$key}.'&' if defined $paramsCommon{$key};
	}
	
	$hot_url = defined $hot_url ? '?'. substr( $hot_url, 0, -1 ) : '';
	
	$hot_url = '' if defined $noParam;

	return 'http://'.$cross_ref->{'IN'}{'server_name'}.'/'
	.($lang eq $cross_ref->{'CONF'}{'diff_language'} ? '' : $lang.'/')
	.($ctrl eq 'index' ? '' : $ctrl.'/')
	.($page eq 'index' ? '' : $page.'/')
	.$hot_url;
}

# Проверка аргументов и их содержимого на соответсвие 
# шаблона указанного в контроллере: ASSAY->(%)

sub argument_checking {

	my (%valids) = @_;

	while (my ($key, $values) = each %{$$cross_ref{'IN'}{'GET'};}) {

		unless (defined $valids{'GET'}{$key}
			&& $values =~ m/$valids{'GET'}->{$key}/s) {

			die "<$$cross_ref{'IN'}{'controller'}> GET method argument error : $!";
		}
	}
	while (my ($key, $values) = each %{$$cross_ref{'IN'}{'POST'};}) {

		unless (defined $valids{'POST'}{$key}
			&& $values =~ m/$valids{'POST'}->{$key}/s) {

			die "<$$cross_ref{'IN'}{'controller'}> POST method argument error : $!";
		}
	}
	return 1;
};
1;