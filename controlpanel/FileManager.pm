package FileManager;
# --------------------------------------------------------------------
use __Run;
use controlpanel::Gallery;

use JSON;
use Encode;
use CGI qw(param);

#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
# --------------------------------------------------------------------

sub init {

	#OUT->{'dumper'} = sub { return '<pre>'.(Dumper #$Gallery::files ).'</pre>' };
	my @files = &_loadFileDir;

	return modalWindow( "@files" );
}

sub _uploadButton {
	return	'<div>'
			.'<div data-event="uploadfile" class="btn btn-default btn-xs pull-right">Загрузить файлы</div>'
			.'<form enctype="multipart/form-data" method="post">
				<!--<label for="fm" class="btn btn-primary btn-xs">Загрузить файлы</label>-->
				<input id="fm" type="file" name="photo" multiple style="">
				</form>'
			.'</div>';
}

sub _loadFileDir {

	my %extEnabled = map { $_ => 1 } qw(png jpeg jpg ico);
		
		
	my $dir = CONF->{'puth_media'}.CONF->{'folder_files'}.'/'.IN->{'referer_params'}{'controller_virt'}.'/';
	
	my (@files, @t);

	opendir (DIR, $dir) or mkdir ($dir) or die "can't cteate folder $dir: $!";

	while (defined(my $file = readdir(DIR))) {
	
		next if $file =~ /^\.\.?$/;

		my $expansion = $1 if $file =~ /\.([^\.]*$)/;
 
		
		my @t = localtime($stat[10]) if @stat = stat $dir.$file;
		
		#next if $stat[7] == 0;
		
		push @files, {
			'size'		=> $stat[7],
			'namefile' 	=> $file,
			'timestamp'	=> $stat[10],
			'expansion'	=> $extEnabled{lc $expansion} ? undef : $expansion,
			'date' 		=> sprintf "%4d-%02d-%02d", $t[5] + 1900, $t[4] + 1, $t[3]
		};
	}

	closedir(DIR);
	
	my @filesSort;
	
	foreach (sort { $b->{'timestamp'} <=> $a->{'timestamp'} } @files) {
	
		push @filesSort, $_;
	}

	return map { _styleFile( IN->{'GET'}{'controller_virt'}, $_ ) } @filesSort;
}

sub _styleFile {

	no warnings;
	
	my $controller = shift;
	my $file = shift;
	
	my @file = split('\/', $file );

	my $puthForFile = 'http://'.IN->{'server_name'}.'/'.CONF->{'folder_files'}.'/'.IN->{'referer_params'}{'controller_virt'}.'/'.$file->{'namefile'};
	my $srcImage = '<img src="'.$puthForFile.'" style="display: inline; max-width: 70px;">';
	
	return '<div style="margin: 20px 0; background-color: #fff;">'
				.'<a href="#">'
					.'<div data-puth="'.CONF->{'folder_files'}.'/'.$controller.'" data-event="getimage" data-file="'.$file->{'namefile'}.'" style="display: inline-block;">'
						.'<div style=" background-color:#fff;text-align: center; float:left; width: 70px; height: 50px; font-weight: 700;">'.($file->{'expansion'} || $srcImage).'</div>'
						.'<div style="padding-left:80px; word-break:break-all;"> '.$file->{'namefile'}.' </div>'
						.'<div style="padding-left:80px;">
							<span style="font-size:8pt; color:#777"> Дата: '.$file->{'date'}.' | Размер: '.((split('\.', $file->{'size'}/1024))[0]).' кб | </span>
							<a href="#" style="font-size:8pt; color:#777" data-event="rmfile" data-puth="'.CONF->{'folder_files'}.'/'.$controller.'" data-file="'.$file->{'namefile'}.'">Удалить</a>'
						.'</div>'
					.'</div>'
				.'</a>'
			.'</div>';
}

sub modalWindow {

	my @text = shift;

	return '
		<div id="fileManager" class="modal fade" style="z-index: 65999">
		  <div class="modal-dialog">
			<div class="modal-content">
			  <!-- Заголовок модального окна -->
			  <div class="modal-header">
				<button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
				<h4 class="modal-title">Диспетчер файлов</h4>
			  </div>
			  <div class="modal-header">
				'._uploadButton.'
			  </div>
			  <!-- Основное содержимое модального окна -->
			  <div class="modal-body">
				'."@text".'
			  </div>
			  <!-- Футер модального окна -->
			  <div class="modal-footer">
				<!-- <button type="button" class="btn btn-default" data-dismiss="modal">Закрыть</button>
				<button type="button" class="btn btn-primary">Сохранить изменения</button> -->
			  </div>
			</div>
		  </div>
		</div>';
}
# --------------------------------------------------------------------
# POST
# --------------------------------------------------------------------

sub _uploadfiles {

	my $onnum = 0;
	
	my $files = [];
	
	my $puth_file = CONF->{'puth_media'}.CONF->{'folder_files'}.'/'.IN->{'referer_params'}{'controller_virt'}.'/';
	
	my $req = new CGI;
	
	my $countFiles = $req->param();
	
	while ($onnum < $countFiles) 
	{
		my $file = $req->param("$onnum");

		if ($file ne "") 
		{
			my $fileName = $file; 

			#$fileName =~ s!^.*(\|/)!!;
			
			$fileName =~ s/[^a-z0-9\.]/_/igu;
			$fileName =~ s/(_){2,}/_/igu;
			
			$fileName = encode('utf8', $fileName);
			
			my @t = localtime();	
			
			push @$files, {
				'namefile' => $fileName, 
				'date' => sprintf "%4d-%02d-%02d", $t[5] + 1900, $t[4] + 1, $t[3]
			};

			open ( OUTFILE,">$puth_file/$fileName" );
			
			binmode OUTFILE;
			
			while (my $bytesread = read($file, my $buffer, 128)) 
			{ 
				print OUTFILE $buffer; 
			} 
			
			close (OUTFILE); 
		}
		$onnum++;
	}
	
	return to_json({
		'files' => [map { _styleFile( IN->{'referer_params'}{'controller'}, $_ ) } @$files],
		'name_files' => $files,
		'ok' => 1
	});
}

sub _removefile {

	my $puthToFile = CONF->{'puth_media'}.CONF->{'folder_files'}.'/'.IN->{'referer_params'}{'controller_virt'}.'/'.IN->{'POST'}{'file'};

	unlink($puthToFile) or die "Can't delete $puthToFile:  $!\n";
	
	return to_json({'ok' => 1});
}

# --------------------------------------------------------------------
1;