package Classify::Web;

use strict;
use warnings;

use Moo;
use AnyEvent::HTTP;
use Data::Dumper;

use feature 'say';

=item $obj->request(REQUEST_METHOD, URL, CB)

Permet à une I<COLLECTION> d'envoyer une requête de manière asynchrone au
I<WEBSITE> souhaité.

=cut
sub request
{
    my($self, $method, $url, $cb) = @_;

    # on envoie la requête
    http_request($method => $url, $self->on_parse($cb));
}

=item $obj->on_parse

On reçoit les données asynchrone : permet de directement transmettre les
informations au destinataire qui les a réclamées.

=cut
sub on_parse
{
    my($self, $cb) = @_;

    return sub
    {
        $cb->();
    }
}

1;
__END__
