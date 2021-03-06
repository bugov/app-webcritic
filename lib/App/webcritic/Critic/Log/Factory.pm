# Class: App::webcritic::Critic::Log::Factory
#   Log factory.
#   Singleton.
package App::webcritic::Critic::Log::Factory;
use Pony::Object qw/-singleton/;
use Module::Load;
  
  protected 'default_log_adaptor' => 'App::webcritic::Critic::Log::Adaptor::Term';
  protected 'log_adaptor';
  protected 'log_adaptor_options' => {};
  
  # Method: init
  #   Constructor
  #
  # Parameters:
  #   $this->log_adaptor - Str|undef - package of log adaptor
  sub init : Public
    {
      my $this = shift;
      $this->log_adaptor = shift || $this->default_log_adaptor;
    }
  
  # Method: set_default_log
  #   setter for default_log_adaptor
  #
  # Parameters:
  #   $this->default_log_adaptor - Str - package of adaptor
  #
  # Returns:
  #   App::webcritic::Critic::Log::Factory
  sub set_default_log : Public
    {
      my $this = shift;
      $this->default_log_adaptor = shift;
      return $this;
    }
  
  # Method: set_log_adaptor_options
  #   setter for log_adaptor_options
  #
  # Parameters:
  #   $this->log_adaptor_options - HashRef
  #
  # Returns:
  #   App::webcritic::Critic::Log::Factory
  sub set_log_adaptor_options : Public
    {
      my $this = shift;
      $this->log_adaptor_options = shift;
      return $this;
    }
  
  # Method: get_log
  #   Create log
  #
  # Parameters:
  #   @_ - adaptor's constructor params
  #
  # Returns:
  #   App::webcritic::Critic::Log::Interface
  sub get_log : Public
    {
      my $this = shift;
      load $this->log_adaptor;
      my %params = (%{ $this->log_adaptor_options }, @_);
      return $this->log_adaptor->new(%params);
    }
  
1;

__END__

=pod

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
