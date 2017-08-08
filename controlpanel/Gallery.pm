package Gallery;
# --------------------------------------------------------------------
use __Run;

use strict;
use JSON;
use Encode;
use Digest::MD5 qw(md5_hex);

#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
# --------------------------------------------------------------------

sub view {

	OUT->{'JavaScript'}{'Link'} = '
		<script src="/js/FileAPI.min.js"></script>
	';
	
	OUT->{'JavaScript'}{'Code'} = &javaScript;
	
	my $getUrlController = IN->{'GET'}{'controller_virt'};
	my $getUrlPage = IN->{'GET'}{'page_virt'};
	
	my $idNavigationVirtQuery = IN->{'GET'}{'id_navigation_virt'};
	
	my $content = QR->('@',"SELECT * FROM pictures_content WHERE id_navigation=? ORDER BY rank ASC;", $idNavigationVirtQuery);
	
	my @pictures;
	
	for my $item ( @$content ) {
	
		my $isActive = $item->[0] eq IN->{'GET'}{'option_extend_img_id'} ? 'class="disabled"' : '';
	
		push @pictures, _styleViewImage($item->[0], $getUrlController, $getUrlPage, $item->[3], $item->[2], $isActive, $item->[5]);
	}
	
	my $ass = '<div class="js-fileapi-wrapper">
					<label for="browse" class="btn btn-default btn-sm">Выберите фотографию (рекомендуется не меньше 1920x1280)</label>
					<input style="display:none" name="photo" id="browse" type="file" multiple accept="image/*"/>
					<div id="escapingBallG">
						<div id="escapingBall_1"></div>
					</div>
					<br /><br />
				</div>';
			
	return $ass."<ul class=\"sortgallery\">@{pictures}</ul>";
}

sub _styleViewImage {

	my $idPicture = shift;
	
	my $getUrlController = shift;
	my $getUrlPage = shift;
	my $sourceFile = shift;
	
	my $nameFile = shift;
	my $isStyleActivePicture = shift;
	
	my 	$timestamp = shift || '';
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($timestamp);
	$timestamp = sprintf "%02d-%02d-%4d", $mday, $mon + 1, $year + 1900 if $timestamp;

	
	my $typeUrlRefererParam = shift;
	
	my $hrefForImage = (defined $typeUrlRefererParam) 
		? URL->($typeUrlRefererParam,'type' => 'gallery','option_extend_img_id' => $idPicture)
		: URL->('type' => 'gallery','option_extend_img_id' => $idPicture);

	my $puthForFile = 'http://'.IN->{'server_name'}.'/'.CONF->{'folder_gallery'}.'/'.$getUrlController.'/'.$getUrlPage.'/thumb/';
	
	return '<li data-id="'.$idPicture.'" '.$isStyleActivePicture.'>
				<div>
					<a href='.$hrefForImage.'>
						<img src="'.$puthForFile.$sourceFile.'" title="'.$nameFile.'">
					</a>
					<span style="font-size:.7em; line-height: 15px; color:#333;">'.$timestamp.'
					<a class="deleteFileGallery"
						data-event="rmfilegallery" data-fileid="'.$idPicture.'" href="#"
						data-toggle="confirmation" data-popout="true" data-title="Удалить файл?"
						data-btn-ok-label="Удалить"
						data-btn-ok-class="btn-default"
						data-btn-cancel-label="Отмена"
						data-btn-cancel-class="btn-info"
						data-title="Удалить файл?" data-content="'.$nameFile.'">
					</a></span>
				</div>
			</li>';
}

sub decription {

	my $buttonSave = shift;
	my $selectLanguage = shift;
	
	my $idNavigationVirtQuery = IN->{'GET'}{'id_navigation_virt'};
	my $getIDImage = IN->{'GET'}{'option_extend_img_id'};

	my $getIdNavigationImage = QR->('$',
		"SELECT id_navigation FROM pictures_content WHERE id=? LIMIT 1;",
		IN->{'GET'}{'option_extend_img_id'}
	);
	
	my $isCheckForExistenceImages = QR->('$',
		"SELECT id FROM pictures_content WHERE id_navigation=? LIMIT 1;",
		$idNavigationVirtQuery
	);
	
	#OUT->{'dumper'} = sub { return '<pre>'.(Dumper $isCheckForExistenceImages).'</pre>' };
	
	if ($idNavigationVirtQuery ne $getIdNavigationImage && defined $isCheckForExistenceImages) {

		$getIDImage = QR->('$',
			"SELECT id FROM pictures_content WHERE id_navigation=? ORDER BY rank ASC;",
			$idNavigationVirtQuery
		);
	
		OUT->{'header'} = [
			'Location' 	=> 	URL->(option_extend_img_id => $getIDImage)
		];		
	
		return 1;
	}
	
	return '' if !defined $isCheckForExistenceImages;
	
	my $contentImage = QR->('%',
		"SELECT * FROM description_pictures_content WHERE id=? AND language=?;",
		$getIDImage,
		$selectLanguage
	);
	
	no warnings;
	
	return	$buttonSave.'<div class="input-group input-group-sm">
				<span class="input-group-addon"><span style="width:200px">Описание</span></span>
				<input name="description_image" type="text" class="form-control" value="'.$contentImage->{'text'}.'" >
			</div><br />
			<div class="input-group input-group-sm">
				<span class="input-group-addon"><span style="width:200px">Видео</span></span>
				<input name="enabled_video" type="text" class="form-control" value="'.$contentImage->{'video'}.'" >
			</div><br /><br />';
}

sub _sortgallery {
	#return to_json(IN);
	
	my $paramSort;
	
	for my $sortList ( split (',', IN->{'POST'}{'sort'}) ) {
		$sortList =~ s/\./\,/;
		$paramSort .= '(' .$sortList. '),';
	}
	
	$paramSort = substr $paramSort, 0, -1;
	
	my $r = QR->('',"INSERT INTO `pictures_content` (id, rank) VALUES $paramSort ON DUPLICATE KEY UPDATE rank = VALUES(rank);");
	
	return to_json({"ok",$r});
}

sub _deleteimagegallery {

	my $queryIdFileOnDelete = shift;
	my $puthToFile = shift;
	
	
	my $sourceNameFile = QR->('$',"SELECT source_file FROM pictures_content WHERE id=?;", $queryIdFileOnDelete);
	
	my $flugDeleteFile = undef;
	
	for ( ('thumb','medium','huge') ) {
		
		my $puthsrc = "$puthToFile/$_/$sourceNameFile";
		
		unlink( $puthsrc );
		
		$flugDeleteFile = "no delete $puthsrc" if( -e $puthsrc );
	}
	
	if ( !defined $flugDeleteFile) {
	
		my $r1 = QR->('',"DELETE FROM `description_pictures_content` WHERE id=?;", $queryIdFileOnDelete);
		my $r2 = QR->('',"DELETE FROM `pictures_content` WHERE id=?;", $queryIdFileOnDelete);
		
		return 1;	
	} else {
	
		return 0;
		die "Couldn't unlink all of $puthToFile:  $!\n";
	}
}

sub deleteImageGallery {

	my $queryIdFileOnDelete = IN->{'POST'}{'file_id'};

	my $puthToFile = CONF->{'puth_media'}.CONF->{'folder_gallery'}.'/'.IN->{'referer_params'}{'controller_virt'}.'/'.IN->{'referer_params'}{'page_virt'};

	my $answer = _deleteimagegallery($queryIdFileOnDelete, $puthToFile);
	
	return to_json({ok => $answer});
}

sub javaScript {

	return <<'EOF';
			(function (){
				if( !(FileAPI.support.html5 || FileAPI.support.flash) ){
					alert('Ooops, your browser does not support Flash and HTML5 :[');
				}
				FileAPI.event.on(browse, 'change', function (evt){
				
					$('#escapingBall_1').addClass('escapingBallG colorTreatmentBallG');
					
					var files = FileAPI.getFiles(evt);
					FileAPI.upload({
						url: '/controlpanel/index?event=uploadimagegallery',
						files: { image: files },
						imageTransform: {
							'thumb': { width: 135, height: 70, preview: true, quality: 0.86 },
							'medium': { maxWidth: 700, preview: true, quality: 0.86 },
							'huge': { maxWidth: 1920, preview: true, quality: 0.86 }
						},
						progress: function (evt){ /* ... */ },
						upload: function (xhr, options){
							$('#escapingBall_1').removeClass('colorTreatmentBallG');
							$('#escapingBall_1').addClass('colorEscapingBallG');
						},
						complete: function (err, xhr, file, options){
							$('#escapingBall_1').removeClass();
						},
						filecomplete: function (err, xhr){ if (!err) {
							var res = JSON.parse(xhr.responseText);
							//console.log(res.file)
							$('.sortgallery').append( res.file );
						}}
					});
				});
			})();
EOF
}


sub _uploadimagegallery {

	my $files = [];
	
	my $puth_file = CONF->{'puth_media'}.CONF->{'folder_gallery'}.'/'.IN->{'referer_params'}{'controller_virt'}.'/'.IN->{'referer_params'}{'page_virt'};

	my $req = new CGI;
	
	my $fileNameOriginal = $req->param('image[original]');
	my $fileNameOriginalMD5 = md5_hex($fileNameOriginal);
	my @excludeFileExpansion = split '\.', $fileNameOriginal;
	my $fileExpansion = lc $excludeFileExpansion[$#excludeFileExpansion];
	
	my $fileNameNew = $fileNameOriginalMD5.'.'.$fileExpansion;
	
	my $maxRank = QR->('$',"SELECT MAX(rank) FROM pictures_content WHERE id_navigation=?;", IN->{'referer_params'}{'id_navigation_virt'});
	
	my $timestamp = time;
	
	my $qrDb = QR->('',"INSERT INTO `pictures_content` (id_navigation, file_name, source_file, rank, date) VALUES (?, ?, ?, ?, ?);",
		IN->{'referer_params'}{'id_navigation_virt'},
		$fileNameOriginal,
		$fileNameNew,
		defined $maxRank ? $maxRank + 1 : 0,
		$timestamp
	);
	
	return to_json({ok => undef}) unless $qrDb == 1;

	for ( ('thumb','medium','huge') ) {
	
		my $categoryFolder = $_;
		
		my $file = $req->param("image[$categoryFolder]");
		
		if ($file ne "") 
		{
			unless (-e $puth_file.'/'.$categoryFolder) {
			
				my $splicePuth;
				
				for (split '\/', $puth_file.'/'.$categoryFolder) {
				
					$splicePuth .= $_.'/';
					
					unless (-e $splicePuth){ 
					
						mkdir ($splicePuth, 755) or die "can't cteate folder $splicePuth: $!";
					} 
				}
			}
						
			my @t = localtime();	
			
			push @$files, {
				'namefile' => $fileNameNew, 
				'date' => sprintf "%4d-%02d-%02d", $t[5] + 1900, $t[4] + 1, $t[3]
			};
		
			
			open ( OUTFILE,">>$puth_file/$categoryFolder/$fileNameNew" );
			
			binmode OUTFILE;
			
			while (my $bytesread = read($file, my $buffer, 128)) { 
			
				print OUTFILE $buffer; 
			} 
			
			close (OUTFILE); 
		}
	}
	
	my $getIdImg = QR->('$',"SELECT id FROM pictures_content WHERE source_file=?;", $fileNameNew);
	
	return to_json({
		'file' => _styleViewImage( 
			$getIdImg,
			IN->{'referer_params'}{'controller_virt'},
			IN->{'referer_params'}{'page_virt'},
			$fileNameNew,
			$fileNameOriginal,
			'draggable="true"',
			$timestamp,
			'referer_params'
		),
		#'files' => [map { _styleFile( IN->{'referer_params'}{'controller_virt'}, $_ ) } @$files],
		'db' => $qrDb,
		'ok' => 1
	});
}

# --------------------------------------------------------------------
1;
