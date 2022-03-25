package GoFloodBot;

use strict;
use warnings;
use Mojo::UserAgent;
use lib 'lib';
use Mojo::Base 'Telegram::Bot::Processor';


my @quotes = ('Лев, может, и король джунглей, но волк в цирке не выступает', 'Если волк молчит то лучше его – не перебивать', 'Никогда не теряйте бдительность, ведь вокруг постоянно кружат волки', 'Если не будешь с волками в стае, то станешь их кормом', 'Если ты родился собакой, не сомневайся, ты таким и будешь', 'Волк живет в постоянном страхе, что его поймут правильно');

sub init { 
  my $self = shift;
  $self->add_listener(\&wiki_search);
}

sub wiki_search {
  my $self   = shift;
  my $update = shift;

  if (ref ($update) eq 'Telegram::Bot::Object::Message') {
    my $message_text = $update->text;

    if ($message_text eq "/auf") {
        $self->sendMessage({chat_id => $update->chat->id, text => "*" . "🐺 ауф 🐺" . "*\n" . $quotes[ rand @quotes ]  . "...", parse_mode => 'Markdown', disable_web_page_preview => 1});

    }
  }
}


my $token = shift;
die "Failed to parse Telegram token" unless $token;

GoFloodBot->new(token => $token)->think;