#!perl

package error;
# --------------------------------------------------------------------

use strict;
use __Run;
__Run::init;

use _extend;
# --------------------------------------------------------------------
OUT->{'_extend'} = _extend::init;

OUT->{'header'} = [
	'Status' 	=> 	"404 Not Found;\nContent-type: text/html;charset=UTF-8"
];	

START->();
# --------------------------------------------------------------------
1;