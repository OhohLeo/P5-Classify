package Classify::Web;

use strict;
use warnings;

use Mojo::DOM;
use AnyEvent::HTTP;
use Data::Dumper;

use Carp;

use Moo;

use feature qw(say switch);

=item url

Retourne l'url du site web.

=cut
sub url
{
    croak "'url' method should be defined in " . ref shift;
}

=item info

Retourne des infos descriptives du site web.

=cut
sub info
{
    croak "'info' method should be defined in " . ref shift;
}

=item $obj->send(REQUEST_METHOD, URL, CB)

Permet à une I<COLLECTION> d'envoyer une requête de manière asynchrone au
I<WEBSITE> souhaité.

=cut
sub send
{
    my($self, $method, $url, $cb) = @_;

    say "send $method => $url";

    # on envoie la requête
    http_request($method => $url, $self->on_parse($cb));
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

        unless (defined $status and $status == 200)
        {
            say "$url not reached ($status)!";
            return;
        }

        $self->rsp($url, Mojo::DOM->new($data), $cb);
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
