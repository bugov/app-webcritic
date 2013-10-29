package App::webcritic::Web;
use mop;
use Socket;
use Module::Load;
use Time::HiRes qw/gettimeofday/;

use App::webcritic::Log;

class Site with App::webcritic::Log::Logger {
  has $!name;
  has $!url;
  has $!domain;
  has $!host;
  has $!first_page;
  has $!page_list = [];
  has $!page_by_url = {};
  has $!exist_page_list = {};
  has $!options;
  
  method new($url, $name, $opts) {
    ($!url, $!name, $!options) = ($url, $name, $opts);
    if ($!options->{log}) {
      $self->set_log_level($!options->{log}->{level}) if $!options->{log}->{level};
      App::webcritic::Log::Factory->new->set_default_log($!options->{log}->{adaptor}) if $!options->{log}->{adaptor};
      App::webcritic::Log::Factory->new->set_log_adaptor_options($!options->{log}->{options}) if $!options->{log}->{options};
      $self->set_log_adaptor(App::webcritic::Log::Factory->get_log())
    }
    $!name ||= 'Site '.$!url;
    ($!domain) = ($!url =~ m/\w+:\/\/([\w\d\-\.:]+)/); # domain with port
    $!host = eval { inet_aton $!domain } || '0.0.0.0';
    $!first_page = App::webcritic::Web::Page->new($self, App::webcritic::Web::Link->new($!url), 1);
    $self->add_page($!first_page);
  }
  
  method check_policies {
    for my $policy (@{$!options->{policies}->{site}}) {
      load $policy->{module};
      my $opts = $policy->{options} ? $policy->{options} : {};
      my $p = $policy->{module}->new($opts)->set_name($policy->{name})
        ->set_site($self)->inspect();
      given ($p->get_status()) {
        when (0) { $self->log_info('All fine at policy "%s"', $policy->{name}) }
        when (1) { $self->log_warn('Something wrong at policy "%s"', $policy->{name}) }
        when (2) { $self->log_error('Too bad at policy "%s"', $policy->{name}) }
      }
    }
  }
  
  method set_log_level(@params) {
    $self->next::method(@params);
    $_->set_log_level($self->get_log_level) for @{$!page_list}
  }
  
  method get_options { $!options }
  method get_page_list { $!page_list }
  
  method parse {
    $self->log_info(qq{Start parse "${!name}"});
    my @pool = @{$!page_list};
    while (my $page = pop @pool) { eval { # parsers may die
      $page->parse();
      sleep($!options->{sleep} || 0);
      for my $link (@{$page->get_link_list()}) {
        my $new_page = App::webcritic::Web::Page->new($self, $link, $page->get_level + 1);
        next if $self->exist_page($new_page) or $self->is_excluded($new_page)
          or ($!options->{level_limit} and $!options->{level_limit} < $new_page->get_level());
        $self->add_page($new_page);
        unshift @pool, $new_page;
        $new_page->check_policies();
      }
    } or $self->log_error($@)}
    $self->log_error(qq{"${!name}" parsed});
  }
  
  method exist_page($page) {
    $!exist_page_list->{$page->url} ? 1 : 0;
  }
  
  method is_excluded($page) {
    return 1 if grep { $page->url =~ /$_/ } @{$!options->{exclude}};
    return 0;
  }
  
  method add_page($page) {
    push @{$!page_list}, $page;
    $!exist_page_list->{$page->url} = 1;
    $!page_by_url->{$page->url} = $page;
  }
  
  method get_page_by_url($url) { $self->page_by_url->{$url} }
}

class Page with role App::webcritic::Log::Logger {
  has $!url;
  has $!link;
  has $!content;
  has $!site;
  has $!scheme;
  has $!visited = 0;
  has $!code;
  has $!time;
  has $!last_modify;
  has $!link_list = [];
  has $!level = 0;
  has $!parent;
  
  method new($site, $link, $level) {
    ($!site, $!link, $!level, $!url) = ($site, $link, $level, $link->url);
    ($!scheme) = ($!url =~ /^(\w+):\/\//);
    $self->set_log_level($!site->get_log_level);
    $self->set_log_adaptor($!site->get_log_adaptor);
  }
  
  method check_policies {
    for my $policy (@{$!site->options->{policies}->{page}}) {
      load $policy->{module};
      my $opts = $policy->{options} || {};
      my $p = $policy->{module}->new($opts);
      $p->set_name($policy->{name})->set_page($self)->inspect;
      
      given ($p->status) {
        when(0) { $self->log_info('All fine at Policy "%s". Page: %s', $policy->{name}, $!url) }
        when(1) { $self->log_warn('Something wrong at policy "%s". Page: %s', $policy->{name}, $!url) }
        when(2) { $self->log_error('Too bad at policy "%s". Page: %s', $policy->{name}, $!url) }
      }
    }
  }
  
  method parse {
    $self->log_info('Looking for '.$this->url);
    my $hrtime0 = gettimeofday;
    
    my $ua = App::webcritic::UserAgent::Factory->new->get_ua($self);
    my ($code, $title, $content, $a_href_list, $img_src_list,
        $link_href_list, $script_src_list, $undef_list) = $ua->get_page();
    
    $!code = $code || 0;
    $!content = App::webcritic::Web::Content->new($code, $title, $content);
    
    $self->add_link_by_url($_, 'a_href')     for @$a_href_list;
    $self->add_link_by_url($_, 'img_src')    for @$img_src_list;
    $self->add_link_by_url($_, 'link_href')  for @$link_href_list;
    $self->add_link_by_url($_, 'script_src') for @$script_src_list;
    $self->add_link_by_url($_, 'undef')      for @$undef_list;
    
    if ($!code == 200) {
      $self->log_info('[%d] %s', $!code, $!url);
    } else {
      $self->log_warn('[%d] %s', $!code, $!url);
    }
    
    my $hrtime1 = gettimeofday;
    my $diff = $hrtime1 - $hrtime0;
    $self->log_info($diff);
    $!time = $diff;
  }
  
  method add_link_by_url($url, $type) {
    return unless $url;
    $self->log_debug('Add link [%10s] %s', $type, $url);
    my $link = App::webcritic::Web::Link->new( $url, $type);
    push @{!link_list}, $link;
  }
}

1;