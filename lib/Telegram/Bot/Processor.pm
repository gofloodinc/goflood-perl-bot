package Telegram::Bot::Processor;

use Mojo::Base -base;

use strict;
use warnings;

use Mojo::IOLoop;
use Mojo::UserAgent;
use Mojo::JSON qw/encode_json/;
use Carp qw/croak/;
use Log::Any;
use Data::Dumper;

use Telegram::Bot::Object::Message;

has longpoll_time => 60;
has ua         => sub { Mojo::UserAgent->new->inactivity_timeout(shift->longpoll_time + 15) };
has token      => sub { croak ""; };

has tasks      => sub { [] };
has listeners  => sub { [] };

has log        => sub { Log::Any->get_logger };



sub add_repeating_task {
  my $self    = shift;
  my $seconds = shift;
  my $task    = shift;

  my $repeater = sub {

    my $last_check = time();
    Mojo::IOLoop->recurring(0.1 => sub {
                              my $loop = shift;
                              my $now  = time();
                              return unless ($now - $last_check) >= $seconds;
                              $last_check = $now;
                              $task->($self);
                            });
  };

  push @{ $self->tasks }, $repeater;

  $repeater->();
}

sub add_listener {
  my $self    = shift;
  my $coderef = shift;

  push @{ $self->listeners }, $coderef;
}

sub init {
  die "failed to init processor";
}

sub think {
  my $self = shift;
  $self->init();

  $self->_add_getUpdates_handler;
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

sub getMe {
  my $self = shift;
  my $token = $self->token || croak "no token?";

  my $url = "https://api.telegram.org/bot${token}/getMe";
  my $api_response = $self->_post_request($url);

  return Telegram::Bot::Object::User->create_from_hash($api_response, $self);
}

sub sendMessage {
  my $self = shift;
  my $args = shift || {};

  my $send_args = {};
  croak "no chat_id supplied" unless $args->{chat_id};
  $send_args->{chat_id} = $args->{chat_id};

  croak "no text supplied"    unless $args->{text};
  $send_args->{text}    = $args->{text};

  $send_args->{parse_mode} = $args->{parse_mode} if exists $args->{parse_mode};
  $send_args->{disable_web_page_preview} = $args->{disable_web_page_preview} if exists $args->{disable_web_page_preview};
  $send_args->{disable_notification} = $args->{disable_notification} if exists $args->{disable_notification};
  $send_args->{reply_to_message_id}  = $args->{reply_to_message_id}  if exists $args->{reply_to_message_id};

  my $token = $self->token || croak "no token?";
  my $url = "https://api.telegram.org/bot${token}/sendMessage";
  my $api_response = $self->_post_request($url, $send_args);

  return Telegram::Bot::Object::Message->create_from_hash($api_response, $self);
}

sub forwardMessage {
  my $self = shift;
  my $args = shift || {};
  my $send_args = {};
  croak "no chat_id supplied" unless $args->{chat_id};
  $send_args->{chat_id} = $args->{chat_id};

  croak "no from_chat_id supplied"    unless $args->{from_chat_id};
  $send_args->{from_chat_id}    = $args->{from_chat_id};

  croak "no message_id supplied"    unless $args->{message_id};
  $send_args->{message_id}    = $args->{message_id};

  $send_args->{disable_notification} = $args->{disable_notification} if exists $args->{disable_notification};

  my $token = $self->token || croak "no token?";
  my $url = "https://api.telegram.org/bot${token}/forwardMessage";
  my $api_response = $self->_post_request($url, $send_args);

  return Telegram::Bot::Object::Message->create_from_hash($api_response, $self);
}

sub _add_getUpdates_handler {
  my $self = shift;

  my $http_active = 0;
  my $last_update_id = -1;
  my $token  = $self->token;

  Mojo::IOLoop->recurring(0.1 => sub {
    return if $http_active;

    my $offset = $last_update_id + 1;
    my $updateURL = "https://api.telegram.org/bot${token}/getUpdates?offset=${offset}&timeout=60";
    $http_active = 1;

    $self->ua->get($updateURL => sub {
      my ($ua, $tx) = @_;
      my $res = $tx->res->json;
      my $items = $res->{result};
      foreach my $item (@$items) {
        $last_update_id = $item->{update_id};
        $self->_process_message($item);
      }

      $http_active = 0;
    });
  });
}

sub _process_message {
    my $self = shift;
    my $item = shift;

    my $update_id = $item->{update_id};
    my $update;
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{message}, $self)             if $item->{message};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{edited_message}, $self)      if $item->{edited_message};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{channel_post}, $self)        if $item->{channel_post};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{edited_channel_post}, $self) if $item->{edited_channel_post};

    if (! $update) {
      die "Failed to handle update: " . Dumper($item);
    }

    foreach my $listener (@{ $self->listeners }) {
      $listener->($self, $update);
    }
}


sub _post_request {
  my $self = shift;
  my $url  = shift;
  my $form_args = shift || {};

  my $res = $self->ua->post($url, form => $form_args)->result;
  if    ($res->is_success) { return $res->json->{result}; }
  else                     { die ""; }
}

1;