package Editor;
# --------------------------------------------------------------------
use __Run;
use controlpanel::Page;
use controlpanel::FileManager;
use controlpanel::Gallery;

use strict;
use JSON;

#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
# --------------------------------------------------------------------

sub init {
	return {'material' => &content};
}

sub content {

	my $getUrlController = IN->{'GET'}{'controller_virt'} || 'index';
	my $getUrlPage = IN->{'GET'}{'page_virt'} || 'index';
	my $isEnabledExtend;
	
	if (CONF->{'controller'}{$getUrlController}{'extend'} && $getUrlPage ne 'index') {
		$isEnabledExtend = 1;
	};
	
	my $tabs;
	
	for my $lang ( sort keys %{CONF->{'language'}} ) {
	
		my $isActive = $lang eq IN->{'GET'}{'language_virt'} ? ' active' : '';
		
		$tabs .= '<li class="dropdown'.$isActive.'">
			<a href="'.URL->(language_virt => $lang).'"><img src="/src/'.$lang.'.png"/> '.$lang.' </a></li>';
	}

	my $contentLanguage .= '<form id="commonform" method="POST" style="margin-top: 15px">'.editor($getUrlController, $getUrlPage).'</div></form>';		

	my $activeButtonCont = IN->{'GET'}{'type'} eq 'content' ? 'btn-info' : 'btn-primary';
	my $activeButtonDesc = IN->{'GET'}{'type'} eq 'description' ? 'btn-info' : 'btn-primary';
	
	$tabs .= '<a style="margin:0 5px" href="'.URL->(type => 'content').'" class="btn '.$activeButtonCont.' btn-xs pull-right">Содержание</a>';
	$tabs .= '<a style="margin:0 5px" href="'.URL->(type => 'description').'" class="btn '.$activeButtonDesc.' btn-xs pull-right">Метатеги</a>';

	
	
	my $fileManager = '';	
	
	if (IN->{'GET'}{'type'} eq 'content') {
	
		$tabs .= '<a style="margin:0 5px" href="#fileManager" class="btn btn-primary btn-xs pull-right" data-toggle="modal">Диспетчер файлов</a>';
		$fileManager = FileManager::init;
	}
	
		
	my $enabledEditorGallery = '';
	my $activeButtonGall = 'btn-primary';
	
	if ($isEnabledExtend && IN->{'GET'}{'type'} eq 'gallery') {
		$activeButtonGall = 'btn-info';
		$enabledEditorGallery = '<div style="padding-bottom: 20px">'.Gallery::view().'</div>';
	}	
	
	if ($isEnabledExtend) {
	
		my $content = QR->('$',"SELECT id FROM pictures_content WHERE id_navigation=? ORDER BY rank ASC;", IN->{'GET'}{'id_navigation_virt'});
		
		$tabs .= '<a style="margin:0 5px" href="'.URL->(type => 'gallery', option_extend_img_id => $content).'" class="btn '.$activeButtonGall.' btn-xs pull-right">Галерея</a>';
	}

	
	#OUT->{'dumper'} = sub { return '<pre>'.(Dumper $mn).'</pre>' };
	
	return	'<div class="tabbable">
			  <div>'.Page::getPageMenu( $getUrlController ).'</div>
			  <div><ul class="nav nav-tabs">'.$tabs.'</ul></div>
			  <div>'.$contentLanguage.'</div>
			  <div>'.$enabledEditorGallery.'</div>
			  <div>'.$fileManager.'</div>
			</div>';
};

sub editor {

	my $getUrlController = shift;
	my $getUrlPage = shift;
	
	my $buttonSave = '<input type="button" style="margin:0 0 15px 0;" class="btn btn-info btn-sm" id="savecommonform" value="Сохранить">';
	
	my $language_virt = IN->{'GET'}{'language_virt'};
	
	my $navigation_virt = QR->('$', "
		SELECT id_navigation FROM core_navigation WHERE controller=? AND page=? AND id_server=? LIMIT 1
	;",	$getUrlController, $getUrlPage, IN->{'GET'}{'id_server'});
	
	my $content = QR->('%',"
		SELECT * FROM core_content WHERE id_navigation=? AND language =? LIMIT 1
	;", $navigation_virt, $language_virt);
		
	
	if (IN->{'GET'}{'type'} eq 'gallery') {
		
		return Gallery::decription ($buttonSave, $language_virt);
		
	} elsif (IN->{'GET'}{'type'} eq 'content') {
	
		OUT->{'JavaScript'}{'Link'} = '
			<script src="/js/tinymce/tinymce.min.js"></script>			
		';

		OUT->{'JavaScript'}{'Code'} = &javaScriptCode;
		
		$content->{'material'} =~ s/\\(["])/$1/gmi;
		
		return	$buttonSave.'
				<textarea name="material" data-editor="tiny" style="width: 100%; height: 60vh" id="textID">'
				.$content->{'material'}.'
				</textarea>';
					
	} elsif (IN->{'GET'}{'type'} eq 'description' || !exists IN->{'GET'}{'type'}) {
	
		no warnings;
		
		return	$buttonSave.'<!--<span class="help-block"></span>-->
				<div class="input-group input-group-sm">
					<span class="input-group-addon"><span style="width:200px">Title</span></span>
					<input name="title" type="text" class="form-control" value="'.$content->{'title'}.'" >
				</div><br />
				<div class="input-group input-group-sm">
					<span class="input-group-addon"><span style="width:200px">Description</span></span>
					<input name="keywords" type="text" class="form-control" value="'.$content->{'keywords'}.'" >
				</div><br />
				<div class="input-group input-group-sm">	
					<span class="input-group-addon"><span style="width:200px">Keywords</span></span>
					<input name="description" type="text" class="form-control" value="'.$content->{'description'}.'" >
				</div>';
	};
}


sub javaScriptCode {
	return <<'EOF'
	
			tinymce.init({
				selector:'textarea[data-editor=tiny]' ,
				language:'ru',
				//height: 590,
				plugins : "autolink,link,lists,pagebreak,table,emoticons,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,template,image,code,imagetools,charmap,textcolor colorpicker",
				
				toolbar: 'undo redo | insert | styleselect | forecolor backcolor | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image',
 
				relative_urls: false,
				convert_urls: false,
				
				image_advtab: true,
				
				extended_valid_elements : 'span[*],script[*]',
				
				file_picker_types: 'file image media',
				
				file_picker_callback: function(cb, value, meta) {
					
					$("#fileManager").modal('show');
					
					$(document).on('click', '[data-event=getimage]', function(){
						var dataParam = $( this ).data();
						cb( '/' + dataParam.puth + '/' + dataParam.file, { title: dataParam.file } );
						$("#fileManager").modal('hide');
						$("[data-file]").off();
					});
				},
				init_instance_callback : function(editor) {
					//console.log( editor );
					//console.log("Editor: " + editor.id + " is now initialized.");
				},
				content_css: [
				'/style/common.css'
				]	
			});
	
EOF
}


sub _upadateCommonDate {

	#return to_json(IN);
	
	#OUT->{'dumper'} = sub { return '<pre>'.(Dumper IN).'</pre>' }; return 1;
	
	my $language_virt = IN->{'referer_params'}{'language_virt'} || CONF->{'diff_language'};
	
	my $navigation_virt = QR->('$','
		SELECT id_navigation FROM core_navigation WHERE controller=? AND page=? AND id_server=? LIMIT 1
		;',	
		IN->{'referer_params'}{'controller_virt'}, 
		IN->{'referer_params'}{'page_virt'}, 
		IN->{'referer_params'}{'id_server'}
	);

	
	if (!defined $navigation_virt) {
		
		QR->('$','
			INSERT INTO `core_navigation` (controller, page, id_server) VALUES (?,?,?)
			;',	
			IN->{'referer_params'}{'controller_virt'}, 
			IN->{'referer_params'}{'page_virt'}, 
			IN->{'referer_params'}{'id_server'}
		);
		
		$navigation_virt = QR->('$','
			SELECT id_navigation FROM core_navigation WHERE controller=? AND page=? AND id_server=? LIMIT 1
			;',	
			IN->{'referer_params'}{'controller_virt'}, 
			IN->{'referer_params'}{'page_virt'}, 
			IN->{'referer_params'}{'id_server'}
		);
				
		QR->('$','
			INSERT INTO `core_content` (id_navigation, language) VALUES (?,?)
			;',	
			$navigation_virt, 
			$language_virt 
		);
	}
	
	my $contentId = QR->('$',"
		SELECT id_content FROM core_content WHERE id_navigation=? AND language =? LIMIT 1
		;", 
		$navigation_virt, $language_virt
	);
	
	if (!defined $contentId) {
		
		QR->('$','
			INSERT INTO `core_content` (id_navigation, language) VALUES (?,?)
			;',	
			$navigation_virt, 
			$language_virt 
		);
		
		$contentId = QR->('$',"
			SELECT id_content FROM core_content WHERE id_navigation=? AND language =? LIMIT 1
			;", 
			$navigation_virt, $language_virt
		);
	}
	
	
	if (IN->{'referer_params'}{'type'} eq 'description') {
		
		QR->('$', '
			INSERT INTO `core_content` (id_content, title, keywords, description) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE 
			title = VALUES(title),
			keywords = VALUES(keywords),
			description = VALUES(description)
			;', 
			$contentId,
			IN->{'POST'}{'title'},
			IN->{'POST'}{'keywords'},
			IN->{'POST'}{'description'}
		);
		
	} elsif (IN->{'referer_params'}{'type'} eq 'content') {
		
		QR->('$', '
			INSERT INTO `core_content` (id_content, material) VALUES (?,?) ON DUPLICATE KEY UPDATE 
			material = VALUES(material)
			;', 
			$contentId,
			IN->{'POST'}{'material'}
		);
	} elsif (IN->{'referer_params'}{'type'} eq 'gallery') {
		
		my $node = QR->('$',"
			SELECT id FROM `description_pictures_content` WHERE id=? AND language=?
			;", 
			IN->{'referer_params'}{'option_extend_img_id'}, $language_virt
		);
		
		QR->('$', '
			INSERT INTO `description_pictures_content` (id, text, video, language) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE 
			text = VALUES(text),
			video = VALUES(video)
			;',
			IN->{'referer_params'}{'option_extend_img_id'},
			IN->{'POST'}{'description_image'},
			IN->{'POST'}{'enabled_video'},
			$language_virt			
		) if !defined $node;		
		
		QR->('%', '
			UPDATE `description_pictures_content` SET text=?, video=? WHERE id=? AND language=? LIMIT 1
			;',
			IN->{'POST'}{'description_image'},
			IN->{'POST'}{'enabled_video'},
			IN->{'referer_params'}{'option_extend_img_id'},
			$language_virt			
		) if defined $node;

	}

	return to_json({ok => 1});
}
# --------------------------------------------------------------------
1;