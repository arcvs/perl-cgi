#!perl

# --------------------------------------------------------------------
package projects; 
# --------------------------------------------------------------------
use strict;

use __Run;
use _extend;
use JSON;

__Run::init('INDEX_RANK' => 1);

#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
# --------------------------------------------------------------------
OUT->{'_extend'} 	= _extend::init;

OUT->{'linkStyleCSS'} = '<link rel="stylesheet" type="text/css" href="/js/fr/fotorama.css?var=1.1" />';
OUT->{'linkJavaScript'} = '
	<script type="text/javascript" src="/js/fr/fotorama.js"></script>
	<script type="text/javascript" src="/js/handlerFotorama.js"></script>
';

my $puth_thumb	= 'http://'.IN->{'server_name'}.'/'.CONF->{'folder_gallery'}.'/'.IN->{'controller'}.'/';
my $puth_medium	= 'http://'.IN->{'server_name'}.'/'.CONF->{'folder_gallery'}.'/'.IN->{'controller'}.'/';
my $puth_huge 	= 'http://'.IN->{'server_name'}.'/'.CONF->{'folder_gallery'}.'/'.IN->{'controller'}.'/';

OUT->{'json'} = &projects_content, START->('json') if exists IN->{'POST'}{'update_gallery'};
OUT->{'material'} = &projects_theme.&projects_content;

#OUT->{'dumper'} = sub { return '<pre>'.(Dumper FIRST_BASE ).'</pre>' };

START->();

sub projects_theme {

	my $img = QR->("@", 
		"SELECT pic.source_file, nav.page FROM pictures_content AS pic INNER JOIN core_navigation AS nav
		ON pic.rank = 0 AND nav.id_navigation = pic.id_navigation AND nav.id_server = ? ORDER BY rank_page ASC;",
		FIRST_BASE->{'id_server'}
	);

	my $lang = IN->{'language'} ne CONF->{'diff_language'} ? IN->{'language'}.'/' : '';

	my $result;

	for (0..@$img-1) {
		$result .= 	"<a href=\"/${lang}projects/$img->[$_][1]\">".
					"<img width=\"252\" src=\"${puth_medium}$img->[$_][1]/medium/$img->[$_][0]\"".
					"data-caption=\"$img->[$_][1]\"></a>";
	}

	return '<div class="preview shadow"><div class="scroll">'.$result.'</div></div>';
}

sub projects_content {
	
	my $img = QR->("@", "
		SELECT 
		pictures_content.file_name,
		pictures_content.source_file,
		description_pictures_content.text,
		description_pictures_content.video
		FROM pictures_content LEFT JOIN description_pictures_content 
		ON pictures_content.id = description_pictures_content.id 
		AND description_pictures_content.language=?
		WHERE pictures_content.id_navigation=? ORDER BY pictures_content.rank ASC
	;", IN->{'language'}, FIRST_BASE->{'id_navigation'}
	);

	my $result = '';
	my @resultAjax = ();
	
	$puth_medium .= FIRST_BASE->{'page'}.'/medium/';
	$puth_thumb .= FIRST_BASE->{'page'}.'/thumb/';
	$puth_huge .= FIRST_BASE->{'page'}.'/huge/';
	
	for ( 0..@$img-1 ) {
	
		if ( exists IN->{'POST'}{'update_gallery'} ){
		
			my $hash = {'img' 		=> $puth_medium.$img->[$_][1],
									'thumb' 	=> $puth_thumb.$img->[$_][1],
									'full' 		=> $puth_huge.$img->[$_][1],
									'caption' => ($img->[$_][2] || '') };
						
			$hash->{'video'} = $img->[$_][3] if $img->[$_][3];
			
			push @resultAjax, $hash;

		} else {
		
			if ( !$img->[$_][3] ) {
				$result .= 	'<img src="'.$puth_medium.$img->[$_][1].
										'" data-thumb="'.$puth_thumb.$img->[$_][1].
										'" data-full="'.$puth_huge.$img->[$_][1].
										'" data-caption="'.($img->[$_][2] || '').'">';
			} else {
				$result .= 	'<a href="'.$img->[$_][3].'"'.
										'data-img="'.$puth_medium.$img->[$_][1].'">'.
										'<img src="'.$puth_thumb.$img->[$_][1].'"></a>';
			}
		}
	}
	
	# можно убрать современем, когда все данные перезапишутся через TyniMCE
	FIRST_BASE->{'material'} =~ s/\\(["])/$1/gmi; 
	

	return to_json({
		'title' => FIRST_BASE->{'title'},
		'text'	=> FIRST_BASE->{'material'},
		'data'	=> \@resultAjax
	}) if ( exists IN->{'POST'}{'update_gallery'} );

	return	'<div class="mainview">'.
				'<div class="fotorama shadow"'.
				'data-nav="thumbs" data-direction="ltr"'.
				'data-minheight="400" data-ratio="16/9"'.
				'data-maxwidth="100%" style="min-height: 400px">
				'.$result.
				'</div>'.
				'<div class="text">'.FIRST_BASE->{'material'}.'</div>
			</div><div class="clear"></div>';
}
# --------------------------------------------------------------------
1;