package Classify::Web::IMDB;
use parent Classify::Web;

use strict;
use warnings;

use Data::Dumper;

use feature 'say';

=item $obj->request(SEARCH, CB)

Permet à une I<COLLECTION> d'envoyer une requête de manière asynchrone au
I<WEBSITE> souhaité.

=cut
sub request
{
    my($self, $search, $cb) = @_;

    $self->SUPER::request('GET', "http://www.imdb.com/find?q=$search", $cb);
}

=item $obj->on_parse

On reçoit ici les données asynchrones : on parse ces données et on les transmet
au destinataire.

=cut
sub on_parse
{
    my($self, $cb) = @_;

    # on reçoit
    return sub
    {
        $cb->();
    }
}

=item $obj->search_page

=cut
sub search_page
{
}

=item $obj->movie_page

=cut
sub movie_page
{
}

=item $obj->character_page

=cut
sub character_page
{
}

1;
__END__
