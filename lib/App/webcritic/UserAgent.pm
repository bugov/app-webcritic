package App::webcritic::UserAgent;
use strict;
use warnings;
use mop;
use Module::Load;

class Interface is abstract {
  method get_page;
}

class Factory {
  has $!ua_adaptor;
  
  method new($adaptor = 'App::webcritic::UserAgent::Adaptor::Mojo', @opts) {
    load $adaptor;
    $!ua_adaptor = $adaptor->new(@opts);
  }
  
  method get_ua { $!ua_adaptor }
}

1;