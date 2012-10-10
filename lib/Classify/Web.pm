package Classify::Web;

use strict;
use warnings;

use Moo;
use AnyEvent::HTTP;
use Data::Dumper;

use feature 'say';

=item $obj->request(REQUEST_METHOD, URL, CB)

Permet � une I<COLLECTION> d'envoyer une requ�te de mani�re asynchrone au
I<WEBSITE> souhait�.

=cut
sub request
{
    my($self, $method, $url, $cb) = @_;

    # on envoie la requ�te
    http_request($method => $url, $self->on_parse($cb));
}

=item $obj->on_parse

On re�oit les donn�es asynchrone : permet de directement transmettre les
informations au destinataire qui les a r�clam�es.

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
