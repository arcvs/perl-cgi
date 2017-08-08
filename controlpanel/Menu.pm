package Menu;
# --------------------------------------------------------------------

use __Run;

#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;

# --------------------------------------------------------------------

sub init {
	return {'menu' => &selectDomen};
}

sub selectDomen {

	my $domainList = QR->('@', "SELECT * FROM server;");
	
	unless (
		exists IN->{'GET'}{'id_server'} && 
		exists IN->{'GET'}{'domain'} && 
		exists IN->{'GET'}{'language_virt'} &&
		exists IN->{'GET'}{'controller_virt'} && 
		exists IN->{'GET'}{'page_virt'} && 
		exists IN->{'GET'}{'type'}
		) {

		OUT->{'header'} = [
			'Location' 	=> 	URL->(
				id_server 			=> $domainList->[0][0], 
				domain					=> $domainList->[0][1],
				language_virt 	=> CONF->{'diff_language'},
				controller_virt => 'index',
				page_virt 			=> 'index',
				type						=> 'description'
			)
		];
		
		START->();
	}

	$list = undef;
	
	for my $key ( @$domainList ) {
		$list .= '<li><a href="'.URL->(
						id_navigation_virt	=> undef,
						language_virt 			=> CONF->{'diff_language'},
						controller_virt 		=> 'index',
						page_virt 					=> 'index',
						id_server 					=> $key->[0], 
						domain							=> $key->[1],
						option_extend_img_id => undef,
						type 								=> 'description'
					).'">'.$key->[1].'</a></li>';
	}

	return '
				<div class="btn-group">
				
				<a class="btn dropdown-toggle" data-toggle="dropdown" href="#" style="color:#000; font-size:14pt">
					'.(IN->{'GET'}{'domain'} || 'Выберите домен').'
					<span class="caret"></span>
				
				</a>
				<ul class="dropdown-menu">
					'.$list.'
				</ul>
				</div>
				<a href="http://'.IN->{'GET'}{'domain'}.'" target="_blank">⇒</a>
				<div class="btn-group">'.&listController.'</div>
			<a class="pull-right buttonPower" href="'.URL->(event_panel => 'exit_from_the_panel').'"></a>';
};

sub listController {

	my $href = undef;
	my $domain = IN->{'GET'}{'domain'};

	for my $item ( @{CONF->{'top_menu_select'}($domain)} ) {
	

		my $active =	((!exists IN->{'GET'}{'controller_virt'} && $item->{'url'} eq 'index') ||
						($item->{'url'} eq IN->{'GET'}{'controller_virt'})) ? 'active' : '';
			
		$href .= '	<li class="btn-sm dropdown '.$active.'">
						<a href="'.URL->(
							#language_virt => CONF->{'diff_language'},
							controller_virt => $item->{'url'},
							page_virt => 'index',
							type => 'description',
							option_extend_img_id => undef,
							id_navigation_virt => undef
						).'">'.
							$item->{IN->{'language'}}.'
						</a>
					</li>';
    }

	#OUT->{'dumper'} = sub { return '<pre>'.@$domainList.(Dumper IN).'</pre>' };

	return '<ul class="nav nav-pills">
			  <!--<li class="nav-header">List header</li>
			  <li class="active"><a href="#">Домой</a></li>-->
			  '.$href.'
			</ul>';
};
# --------------------------------------------------------------------
1;
