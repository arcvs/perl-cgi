#!perl

package partners;
# --------------------------------------------------------------------

use __Run;
__Run::init;

use strict;
use _extend;

# --------------------------------------------------------------------

OUT->{'_extend'} = _extend::init;

START->();
# --------------------------------------------------------------------
1;