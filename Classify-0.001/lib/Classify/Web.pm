package Classify::Web;
use parent Classify::Base;

use strict;
use warnings;

use Mojo::DOM;
use AnyEvent::HTTP;
use Data::Dumper;

use Carp;
use Moo;

use feature 'switch';

use constant
{
    MAX_REQUEST => 3,
};

has count => (
   is => 'rw',
 );

has waiting => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item BUILD

Initialise request counter.

=cut
sub BUILD
{
    my $self = shift;

    $self->count(0);
}

=item url

Retourne l'url du site web.

=cut
sub url
{
    croak "'url' method should be defined in " . ref shift;
}

=item $obj->send(REQUEST_METHOD, URL, CB)

Permet à une I<COLLECTION> d'envoyer une requête de manière asynchrone au
I<WEBSITE> souhaité.

=cut
sub send
{
    my($self, $method, $url, $cb) = @_;

     # we check how many requests have been sent
    if ($self->count >= MAX_REQUEST)
    {
        $self->waiting([]) unless defined $self->waiting;

        push($self->waiting, $method, $url, $cb);

        return;
    }

    $self->log_great("send $method => $url");

    # we send the request
    http_request($method => $url, $self->on_parse($cb));

    # we increment the counter
    $self->count($self->count + 1);
}

=item $obj->on_parse

Reçoit les données asynchrone : cela permet de filtrer les requêtes qui ont
abouties et d'appeler la méthode get_response avec les données.

=cut
sub on_parse
{
    my($self, $cb) = @_;

    return sub
    {
        my($data, $headers) = @_;

        my($status, $url) = ($headers->{Status}, $headers->{URL});

        if (defined $status and $status == 200)
        {
            $self->rsp($url, Mojo::DOM->new($data), $cb);
        }
        else
        {
            $self->log_warn("$url not reached ($status)!");
        }

        # we decrement the counter
        $self->count($self->count - 1);

        # if no more request exits
        if ($self->count == 0)
        {
            $self->waiting(undef) ;
            return;
        }

        # otherwise we handle requests stored
        if (defined $self->waiting and $self->count < MAX_REQUEST)
        {
            $self->send(splice($self->waiting, 0, 3));
        }
    };
}

=item $obj->rsp

Cette méthode DOIT être implémenté par le service qui parse la page web.

=cut
sub rsp
{
    croak("'rsp' MUST be implemented!");
}

=item $obj->format_search

Formate et retourne la requête.

=cut
sub format_search
{
    my(undef, $search) = @_;

    $search =~ s/^ //g;
    $search =~ s/ $//g;
    $search =~ s/  / /g;
    $search =~ s/ /+/g;

    return lc $search;
}

1;
__END__
