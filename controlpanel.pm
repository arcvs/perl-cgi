#!perl

package controlpanel;
# --------------------------------------------------------------------
use strict;
use __Run;
__Run::init (__ACCESS_OFF => 1);

#use _extend;
use controlpanel::Menu;

use controlpanel::Editor;
use controlpanel::Page;
use controlpanel::FileManager;
use controlpanel::Gallery;

use JSON;
use Digest::MD5 qw(md5_hex);
#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
# --------------------------------------------------------------------



# Генерация ключа доступа, запись в файл key.txt и core_user

if (IN->{'page'} eq 'generate_new_key') {

	OUT->{'title'} = 'Генерация нового ключа';
	
	OUT->{'template'} = 'tpl/generatekey.tpl';
	
	if (exists IN->{'POST'}{'generate'}) {
	
		my $newKey = '='.md5_hex(rand()).'=';
	
		open (OUTFILE, ">".CONF->{'puth_to_file_key'}) || die "dont open/create file secr* $!";
		print OUTFILE "$newKey";
		close (OUTFILE);
		
		if ($newKey) {
			QR->('','DELETE FROM `core_session`');
			QR->('','UPDATE `core_user` SET pass=? WHERE id=?', $newKey, 2);
		}
	
		OUT->{'header'} = [
			'Location' 	=> 	URL->('no_params', ctrl => 'controlpanel', page => 'index')."\nSet-Cookie:_s=0;path=/;"
			#'Location' 	=> 	URL->('no_params', ctrl => 'controlpanel')."\nSet-Cookie:_s=0;path=/;"
		];
	}
	
	START->();
}


OUT->{'title'} = 'Панель управления';


# Проверка переменной exit_from_the_panel для выхода из админ-панели

if ( exists IN->{'GET'}{'event_panel'} && IN->{'GET'}{'event_panel'} eq 'exit_from_the_panel') {

	OUT->{'header'} = [
		'Location' 	=> 	URL->('no_params', ctrl => 'controlpanel')."\nSet-Cookie:_s=0;path=/;"
	];
}


# Авторизация пользователя 

my $success = 0;

if ( exists IN->{'get_cookies'}{'_s'} && IN->{'get_cookies'}{'_s'} ne '0' ) { 

	my $idUser = QR->('$','
		SELECT id_user FROM core_session WHERE session=? LIMIT 1
		;',
		IN->{'get_cookies'}{'_s'}
	);
	 
	$success = 1 if $idUser;
}

# Аунтификация пользователя
	
unless ($success) {

	if (exists IN->{'POST'}{'password'}) {
	
		my $idUserSucc = QR->('$','
			SELECT id FROM core_user WHERE pass=? LIMIT 1
			;',
			IN->{'POST'}{'password'}
		);
		
		if ($idUserSucc) {
		
			my $session = md5_hex(rand());
		
			QR->('','INSERT INTO `core_session` (session, id_user) VALUE (?, ?)', $session, $idUserSucc);
		
			OUT->{'header'} = [
				'Location' 	=> 	URL->('no_params', ctrl => 'controlpanel')."\nSet-Cookie:_s=".$session.";path=/;"
			];	
		}
	}
	
	OUT->{'template'} = 'tpl/admission.tpl';
	
	START->();
}


if (IN->{'method'} eq 'POST' && exists IN->{'GET'}{'event'}) {

	#OUT->{'json'} = to_json(IN);
	
	OUT->{'json'} = Editor::_upadateCommonDate if IN->{'GET'}{'event'} eq 'upadatecommondate';
	
	OUT->{'json'} = Page::_setSortPageMenu if IN->{'GET'}{'event'} eq 'sortpagemenu';

	OUT->{'json'} = Gallery::_sortgallery if IN->{'GET'}{'event'} eq 'sortgallery';
	OUT->{'json'} = Gallery::_uploadimagegallery if IN->{'GET'}{'event'} eq 'uploadimagegallery';
	OUT->{'json'} = Gallery::deleteImageGallery if IN->{'GET'}{'event'} eq 'deleteimagegallery';
		
	OUT->{'json'} = FileManager::_uploadfiles if IN->{'GET'}{'event'} eq 'uploadfiles';
	OUT->{'json'} = FileManager::_removefile if IN->{'GET'}{'event'} eq 'removefile';
	
	START->('json');
}

if (IN->{'method'} eq 'POST') {
	
	Page::_createPage if exists IN->{'POST'}{'createpage'};
	Page::_updatePage if exists IN->{'POST'}{'updatepage'};
	Page::_deletePage if exists IN->{'POST'}{'deletepage'};
	
	START->();
}

#OUT->{'dumper'} = sub {return '<pre>'.(Dumper IN).'</pre>';};

OUT->{'template'} = 'tpl/controlpanel.tpl';
OUT->{'MenuMain'} = Menu::init;
OUT->{'Editor'}		= Editor::init;

START->();

# --------------------------------------------------------------------
1;