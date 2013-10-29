package App::webcritic::Log::Adaptor;
use mop;
use strict;
use warnings;

class Interface is abstract {
  method render;
  method add_message;
}

class Term extends App::webcritic::Log::Adaptor::Interface {
  use Term::ANSIColor;
  
  has $!message_list = [];
  has $!log_color = {
    debug => 'white',
    info  => 'bright_white',
    warn  => 'cyan',
    error => 'yellow',
    fatal => 'red',
  };
  has $!path;
  
  # Render/store/etc message_list.
  method render {
    my $res = *STDOUT;
    eval { # don't fail
      for my $msg (@{$!message_list}) {
        my $content = @{$msg->params} ?
          sprintf $msg->format, @{$msg->params} :
          sprintf $msg->format;
        print color $!log_color->{$msg->level};
        printf $res "[%5s] %s\n", $msg->level, $content;
        print color 'reset';
      }
    }
  }
  
  # Add message into message_list.
  method add_message(@messages) {
    push @{$!message_list}, @messages;
    $self->render;
  }
}

class SimpleTerm extends App::webcritic::Log::Adaptor::Interface {
  has $!message_list = [];
  has $!path;
  
  # Open target file if exists.
  method new($path) {
    $!path = $path;
    if (-d $!path) {
      my ($s, $m, $h, $d, $M, $y) = map {$_ < 10 ? "0$_" : $_} localtime;
      $y += 1900;
      $M += 1;
      $M = $M < 10 ? "0$M" : $M;
      $!path .= "/$y-$M-${d}_$h-$m-$s.log";
      open(my $fh, '>>', $!path) or die "Can't write to ".$!path;
      close $fh;
    } else {
      die "Can't find log dir ".$!path;
    }
  }
  
  # Render/store/etc message_list.
  method render {
    my $res;
    if (-w $!path) { open($res, '>>', $!path) }
    else { $res = *STDOUT }
    eval { # don't fail
      for my $msg (@{$!message_list}) {
        my $content = @{$msg->params} ?
          sprintf $msg->format, @{$msg->params} :
          sprintf $msg->format;
        printf $res "[%5s] %s\n", $msg->level, $content;
      }
    };
    close $res if -w $!path;
  }
  
  # Add message into message_list.
  method add_message(@messages) {
    push @{$!message_list}, @messages;
    $self->render;
  }

}

1;

__END__

=pod

=head1 NAME

Adaptors for App::webcritic::Log

=head1 OVERVIEW

This package provides adaptors for logging.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, Georgy Bazhukov aka bugov <gosha@bugov.net>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
