package Classify::Import;

use strict;
use warnings;

use Carp;

use Moo;

has collections => (
   is => 'rw',
 );

=item launch

M�thode devant �tre impl�ment�e dans tous les imports.

=cut
sub launch
{
    croak "'launch' method not implemented in " . ref(shift);
}

=item feed_collections

M�thode permettant d'envoyer les donn�es aux collections � qui elles sont
destin�es.

=cut
sub feed_collections
{
    my($self, @input) = @_;

    return unless defined $self->collections;

    foreach my $collection (@{$self->collections})
    {
        $collection->input(@input);
    }
}

1;
__END__
