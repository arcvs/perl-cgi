package _extend;
# --------------------------------------------------------------------
use strict;
use __Run;
# --------------------------------------------------------------------

sub init {
	return {
		'selectLanguage'	=> &language,
		'headerMenu'			=> &header_menu,
		'metrikaScript'		=> &metrikaScript,
		'currentYear'			=> &getCurentYaer
	};
};

sub getCurentYaer {
	
	my @time = localtime (time);

	return $time[5] + 1900;
}

sub metrikaScript {

	return CONF->{'metrika_yandex'};
}

sub language {
	
	my $language 	= IN->{'language'};
	my $ctrl = IN->{'controller'} ne 'index' ? URL->(lang => $language) : '';

	return 	'<a class="ru '.($language ne 'ru'?'active_local':'').
					'" href="'.URL->(lang => 'ru').'" title="Russian"></a>'.
					'<a class="en '.($language ne 'en'?'active_local':'').
					'" href="'.URL->(lang => 'en').'" title="England"></a>';
};

sub header_menu {

	my $language	= 	IN->{'language'};

	my $lang_href 	= 	$language ne 'ru' ? $language.'/' : '';

	my $href = undef;
	
    for my $key ( @{CONF->{'top_menu'}} ) {

		$href .= '<li><a href="'.
							'http://'.IN->{'server_name'}.'/'.
							$lang_href.
							$key->{'url'}.'/">'.
							$key->{$language}.'</a></li>';
    }

	return $href;
}
# --------------------------------------------------------------------
1;
