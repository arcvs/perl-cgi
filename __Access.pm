package __Access;

use strict;

sub new {

	my $self  	= shift;
	
	return 1 if $self->{'MODE'}{'__ACCESS_OFF'};
	
	my $cfg 	= $self->{'CONF'};
	my $in 		= $self->{'IN'};
	my $qr 		= $self->{'QR'};
	
	my $user = {};
	
	# ! сделать проверку на 0 после получение не созданной сессии

	#$user = $qr->('%',"SELECT * FROM core_user AS u
	#	INNER JOIN core_session AS s
	#		ON s.session = ?
	#		AND s.ip = ?
	#	INNER JOIN core_group_policy AS gp
	#		ON u.id = s.id_user
	#		AND gp.id_group_policy = u.id_group_policy LIMIT 1;",
	#		$in->{'get_cookies'}->{'ID'},
	#		$in->{'ip_address'}
	#		);

	#unless ( defined $user->{'id'} ) {

	#	$user = $qr->('%',"SELECT * FROM core_user AS u
	#		INNER JOIN core_group_policy AS gp
	#			ON u.id = 1
	#			AND gp.id_group_policy = u.id_group_policy LIMIT 1");
	#}
	
	#$self->{'USER'} = $user;
	
	## undef %$user_policy, $user_policy;
#==========================================================================

	
	my $access = {};
	
	#grep {$_ eq $in->{'controller'}} $user->{'module'}
	#	|| $user->{'module'}->[0] eq 'full_access'
	#	|| die "denied access to the controller: $!";

	my $id_server = $qr->('%',"SELECT id_server FROM server WHERE name=? LIMIT 1;", $in->{'server_name'});
	
	my $navigation = $self->{'MODE'}{'INDEX_RANK'} && $in->{'page'} eq 'index'
	
		?	$qr->('%', "SELECT * FROM core_navigation WHERE controller=? AND rank_page=? AND id_server=? LIMIT 1;",
			$in->{'controller'}, $self->{'MODE'}{'INDEX_RANK'}, $id_server->{'id_server'})
			
		:	$qr->('%', "SELECT * FROM core_navigation WHERE controller=? AND page=? AND id_server=? LIMIT 1;",
			$in->{'controller'}, $in->{'page'}, $id_server->{'id_server'});
	
	$self->{'FIRST_BASE'} = $qr->('%', "SELECT * FROM core_content WHERE id_navigation=? AND language=? LIMIT 1;",
		$navigation->{'id_navigation'}, $in->{'language'});
		
	if (!defined $navigation->{'id_navigation'}) {die 'page not found'};
	
	$self->{'FIRST_BASE'}{'id_server'} 		= $id_server->{'id_server'};
	$self->{'FIRST_BASE'}{'id_navigation'}	= $navigation->{'id_navigation'};
	$self->{'FIRST_BASE'}{'controller'}		= $navigation->{'controller'};
	$self->{'FIRST_BASE'}{'page'}			= $navigation->{'page'};
	
	# $access->{'primary_base'} || die 'data on the page is not found: $!';
	
	return 1;
}
1;
