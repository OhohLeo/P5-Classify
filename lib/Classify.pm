package Classify;

# ABSTRACT: Classify : simply manage your collections!

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;

use Classify::Web;
use Classify::Traduction;
use Classify::Display::Main;

use Moo;

use Data::Dumper;

use feature 'say';

has condvar => (
   is => 'rw',
 );

has web => (
   is => 'rw',
 );

has collections => (
   is => 'rw',
 );

has graphic => (
   is => 'rw',
 );

sub BUILD
{
    my($self, $graphic) = @_;

    # anyevent condvar initialisation
    $self->condvar(AnyEvent->condvar);

    # website initialisation
    $self->web(Classify::Web::->new());

    # collections initialisation
    $self->collections({});

    # graphical initialisation
    if (defined $graphic)
    {
        $self->graphic(
            Classify::Display::Main::->new(
                trad => Classify::Traduction::->new(data => 'FR'),
                on_stop => sub { $self->stop }));
    }

    # we launch the application
    $self->start;
}

sub start
{
    my $self = shift;

    say "Classify is starting up.";

    # start graphic
    $self->graphic->start if defined $self->graphic;

    # start anyevent
    $self->condvar->recv;
}

sub stop
{
    my $self = shift;

    # stop anyevent
    $self->condvar->send;

    say "Classify stopped.";
}

1;
__END__
