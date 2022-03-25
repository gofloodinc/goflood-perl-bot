package Telegram::Bot::Objects::Message;

use Mojo::Base 'Telegram::Bot::Objects::Base';

use Telegram::Bot::Objects::Chat;
use Telegram::Bot::Objects::MessageEntity;

use Data::Dumper;

has 'message_id';
has 'from';  
has 'date';
has 'chat';  

has 'forward_from'; 
has 'forward_from_chat';
has 'forward_from_message_id';
has 'forward_signature';
has 'forward_sender_name';
has 'forward_date';

has 'reply_to_message';
has 'edit_date';
has 'media_group_id';
has 'author_signature';
has 'text';
has 'entities';

sub fields {
  return {
          'Telegram::Bot::Object::Chat'                 => [qw/chat forward_from_chat/],
          'Telegram::Bot::Object::Message'              => [qw/reply_to_message pinned_message/],
          'Telegram::Bot::Object::MessageEntity'        => [qw/entities caption_entities /],
  };
}

sub reply {
  my $self = shift;
  my $text = shift;
  return $self->_processor->sendMessage({chat_id => $self->chat->id, text => $text});
}

1;