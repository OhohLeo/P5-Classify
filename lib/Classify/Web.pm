package Classify::Web;

use strict;
use warnings;

use Mojo::DOM;
use AnyEvent::HTTP;
use Data::Dumper;

use Moo;

use feature 'say';

=item $obj->send(REQUEST_METHOD, URL, CB)

Permet � une I<COLLECTION> d'envoyer une requ�te de mani�re asynchrone au
I<WEBSITE> souhait�.

=cut
sub send
{
    my($self, $method, $url, $cb) = @_;

    say "send $method => $url";

    # on envoie la requ�te
    http_request($method => $url, $self->on_parse($cb));
}

=item $obj->on_parse

Re�oit les donn�es asynchrone : cela permet de filtrer les requ�tes qui ont
abouties et d'appeler la m�thode get_response avec les donn�es.

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

=item $obj->get_response

Cette m�thode DOIT �tre impl�ment� par le service qui parse la page web.

=cut
sub rsp
{
    croak("'get_response' MUST be implemented!");
}

=item $obj->format_search

Formate et retourne la requ�te.

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
