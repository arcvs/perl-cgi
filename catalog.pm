#!perl

package catalog; 
# --------------------------------------------------------------------
use strict;

use __Run;
use _extend;
use JSON;

__Run::init({'INDEX_RANK' => 1});

#use Data::Dumper;
#local $Data::Dumper::Sortkeys = 1;
# --------------------------------------------------------------------
OUT->{'linkStyleCSS'} = '<link rel="stylesheet" type="text/css" href="/js/fr/fotorama.css?var=1.1" />';
OUT->{'linkJavaScript'} = '
	<script type="text/javascript" src="/js/fr/fotorama.js"></script>
	<script type="text/javascript" src="/js/handlerFotorama.js"></script>
';

1;