#!perl

package index;
# --------------------------------------------------------------------
use __Run;
__Run::init();

use strict;
use _extend;
#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
# --------------------------------------------------------------------

OUT->{'_extend'} = _extend::init;

#OUT->{'dumper'} = sub {return '<pre>'.(Dumper IN).'</pre>';};

START->();
# --------------------------------------------------------------------
1;

#ASSAY -> (
	# POST	=> {e => '^[c]+$'},
	# GET	=> {e => '3'},
#);