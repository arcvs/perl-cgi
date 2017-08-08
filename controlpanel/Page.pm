package Page;
# --------------------------------------------------------------------
use __Run;
use controlpanel::FileManager;
use controlpanel::Gallery;

use strict;
use JSON;

#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
# --------------------------------------------------------------------

sub getPageMenu {

	my $controller = IN->{'GET'}{'controller_virt'};
	my $idServer = IN->{'GET'}{'id_server'};
	
	my $listContrlPage = QR->("@", "SELECT * FROM core_navigation WHERE controller=? AND id_server=? ORDER BY rank_page ASC;", $controller, $idServer);
	
	
	#my $domain = IN->{'GET'}{'domain'};
	#my %optionCurrentController = map { $_ => 1 } CONF->{'top_menu_select'}($domain);
	#OUT->{'dumper'} = sub { return '<pre>'.( Dumper scalar @$listContrlPage ).'</pre>' };
	#return '' if scalar @{$img} <= 1;
	
	my $menu;
	
	
	
	for my $item ( @$listContrlPage ) {
	
		my $isActive = IN->{'GET'}{'page_virt'} eq $item->[2] ? 'btn-primary' : 'btn-default';
		
		#my $typeMenu = $item->[2] eq 'index' ? 'description' : 'gallery'; # bofore URL(, type => $typeMenu
	
		$menu .= '<li data-id="'.$item->[0].'">
								<a class="btn '.$isActive.' btn-xs" href="'
								.URL->(controller_virt => $controller, page_virt => $item->[2], id_navigation_virt => $item->[0]).'">'.$item->[2].'</a>
							</li>';
	}

	my $extOptionPage = IN->{'GET'}{'page_virt'} ne 'index' 
			? '
			<form method="POST" style="float:left;padding:0;margin:0">
				<input name="deletepage" href="#" onclick="return confirm(\'Все данные включая фотографии будут уничтожены. Удалить раздел?\')" type="submit" class="btn btn-danger btn-xs" style="float:left;margin:4px 5px 0;line-height:12px;"
				value="Удалить раздел">
			</form>
			' : '';

	return '<div style="padding: 0 20px 15px 0">
				<span style="float:left;font-weight: bold;">'.IN->{'GET'}{'page_virt'}.' -</span>
				<a id="showHideBlockOptionPage" href="#" style="float:left; padding: 0 20px 15px 10px">параметры</a>
				
				<div id="optionPage" class="hidden" style="float:left;">

					<a id="showHideBlockCreatingPage" href="#" class="btn btn-info btn-xs" style="float:left;margin:4px 5px 0;line-height:12px;"> Новый раздел </a>
					
					<form method="POST" style="float:left;padding:0;margin:0">
						<div id="inputNameCreatingPage" class="hidden" style="float:left;">
							<input name="namepagecreate" type="text" placeholder="[a-z][0-9][-][_]">
							<input name="createpage" type="submit" class="btn btn-warning btn-xs" value="Создать">
						</div>
					</form>
					
					'.$extOptionPage.'
					
				</div>
			
			</div>
			<div style="clear:both"></div>
			<ul class="sortmenu">'.(scalar @$listContrlPage > 1 ? $menu : '').'</ul><br />';
}


sub _deletePage {

	my $idNavigationVirt = IN->{'GET'}{'id_navigation_virt'};
		
	my $coreNavig = QR->('%','
		SELECT controller, page FROM `core_navigation` WHERE id_navigation=? LIMIT 1
		;',
		$idNavigationVirt
	);
	
	my $puthToFile = CONF->{'puth_media'}.CONF->{'folder_gallery'}.'/'.$coreNavig->{'controller'}.'/'.$coreNavig->{'page'};
	
	my $listPhotos = QR->('@','SELECT id FROM `pictures_content` WHERE id_navigation=?', $idNavigationVirt);
	
	for my $idPhoto ( @$listPhotos ) {
	
		Gallery::_deleteimagegallery($idPhoto->[0], $puthToFile);
	}
	
	QR->('$','DELETE FROM `core_content` WHERE id_navigation=?;', $idNavigationVirt);
	QR->('$','DELETE FROM `core_navigation` WHERE id_navigation=? LIMIT 1;', $idNavigationVirt);
	
	OUT->{'header'} = [
		'Location' 	=> 	URL->(page_virt => 'index', type => 'description')
	];
	
	return to_json({ok => 1});
}

sub _createPage {
	#return to_json(IN);
	
	my $controller = IN->{'GET'}{'controller_virt'};
	my $idServer = IN->{'GET'}{'id_server'};
	my $nameNewPage = IN->{'POST'}{'namepagecreate'};
	
	#OUT->{'dumper'} = sub { return '<pre>'.(Dumper $nameNewPage).'</pre>' };
	
	
	
	# проверка начальной страницы index
	
	my $idIndex = QR->('$','
		SELECT id_navigation FROM `core_navigation` WHERE controller=? AND page=? AND id_server=? LIMIT 1
		;',
		$controller,
		'index',
		$idServer
	);
	
	# если страницы index не найдена то создаем
	
	unless (defined $idIndex) {
		QR->('$','
			INSERT INTO `core_navigation` (controller, page, rank_page, id_server) VALUES (?, ?, ?, ?)
			;',
			$controller,
			'index',
			0,
			$idServer
		);
	}
	
	


	
	my $id = QR->('$','
		SELECT id_navigation FROM `core_navigation` WHERE controller=? AND page=? AND id_server=? LIMIT 1
		;',
		$controller,
		$nameNewPage,
		$idServer
	);
	
	die ("Страница с таким именем уже $nameNewPage существует") if (defined $id);
	
	my $maxRank = QR->('$','
		SELECT MAX(rank_page) FROM `core_navigation` WHERE controller=? AND id_server=?
		;',
		$controller,
		$idServer
	);
	
	#return to_json({ok => $maxRank});
	
	QR->('$','
		INSERT INTO `core_navigation` (controller, page, rank_page, id_server) VALUES (?, ?, ?, ?)
		;',
		$controller,
		$nameNewPage,
		defined $maxRank ? $maxRank + 1 : 0,
		$idServer
	);
	
	$id = QR->('$','
		SELECT id_navigation FROM `core_navigation` WHERE controller=? AND page=? AND id_server=?
		;',
		$controller,
		$nameNewPage,
		$idServer
	);
	
	OUT->{'header'} = [
		'Location' 	=> 	URL->(page_virt => $nameNewPage, id_navigation_virt => $id)
	];		
	
	return 1;
}

sub _setSortPageMenu {
	#return to_json(IN);
	
	my $paramSort;
	
	for my $sortList ( split (',', IN->{'POST'}{'sort'}) ) {
		$sortList =~ s/\./\,/;
		$paramSort .= '(' .$sortList. '),';
	}
	
	$paramSort = substr $paramSort, 0, -1;
	
	my $r = QR->('',"INSERT INTO `core_navigation` (id_navigation, rank_page) VALUES $paramSort ON DUPLICATE KEY UPDATE rank_page = VALUES(rank_page);");
	
	return to_json({ok => $r});
}



# TASK: UPDATE возможно использование, можно было бы доделать изменение папки, где хранятся фотографии

sub _updatePage {

	my $controller = IN->{'GET'}{'controller_virt'};
	my $namePage = IN->{'GET'}{'page_virt'};
	my $idServer = IN->{'GET'}{'id_server'};
	
	my $nameUpdatePage = lc IN->{'POST'}{'namepageupdate'};
	
	my $idNavigation = QR->('$','
		SELECT id_navigation FROM `core_navigation` WHERE controller=? AND page=? AND id_server=? LIMIT 1
		;',
		$controller,
		$namePage,
		$idServer
	);
	
	die ("Раздел с именем $namePage для изменения не найден > новое имя $nameUpdatePage") if ( !defined $idNavigation );
	
	my $id = QR->('$','
		UPDATE `core_navigation` SET page=? WHERE id_navigation=?
		;',
		$nameUpdatePage,
		$idNavigation
	);
	
	OUT->{'header'} = [
		'Location' 	=> 	URL->(page_virt => $nameUpdatePage)
	];		
	
	return 1;
}

# --------------------------------------------------------------------
1;
