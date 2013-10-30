package App::webcritic::Log;
use strict;
use warnings;
use mop;

use App::webcritic::Log::Adaptor;

role Logger {
  has $!log_level;
  has $!log_adaptor;
  has $!log_level_list is ro = {
    debug => 00,
    info  => 20,
    warn  => 40,
    error => 60,
    fatal => 80,
    off   => 99,
  };
  
  method set_log_level($log_level) {
    $!log_level = $log_level;
  }
  
  method get_log_level {
    return $!log_level;
  }
  
  method set_log_adaptor($adaptor) {
    $!log_adaptor = $adaptor;
  }
  
  method get_log_adaptor {
    return $!log_adaptor;
  }
  
  method write_log($level, @content) {
    my $format = shift @content;
    my $message = @content ?
      App::webcritic::Log::Message->new($level, $format, \@content) :
      App::webcritic::Log::Message->new($level, $format, []);
    $!log_adaptor ||= App::webcritic::Log::AdaptorFactory->new->get_log();
    $!log_adaptor->add_message($message);
  }
  
  method log_debug(@content) {
    return if $!log_level_list->{debug} < $!log_level;
    $self->write_log('debug', @content);
  }
  
  method log_info(@content) {
    return if $!log_level_list->{info} < $!log_level;
    $self->write_log('info', @content);
  }
  
  method log_warn(@content) {
    return if $!log_level_list->{warn} < $!log_level;
    $self->write_log('warn', @content);
  }
  
  method log_error(@content) {
    return if $!log_level_list->{error} < $!log_level;
    $self->write_log('error', @content);
  }
  
  method log_fatal(@content) {
    return if $!log_level_list->{fatal} < $!log_level;
    $self->write_log('fatal', @content);
  }
}

class Message {
  has $!level;
  has $!format;
  has $!params = [];
  
  method new($level, $format, $params) {
    ($!level, $!format, $!params) = ($level, $format, $params);
  }
}

class AdaptorFactory {
  has $!log_adaptor;
  
  method new($adaptor = 'App::webcritic::Log::Adaptor::Term', @opts) {
    load $adaptor;
    $!log_adaptor = $adaptor->new(@opts);
  }
  
  method get_log { $!log_adaptor }
}

1;

__END__

=pod

=head1 NAME

Log for App::webcritic

=head1 OVERVIEW

This package provides Logger role (for logging).

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, Georgy Bazhukov aka bugov <gosha@bugov.net>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
