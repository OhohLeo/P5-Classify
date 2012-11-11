package Classify::Import;

use strict;
use warnings;

use Carp;

use Moo;

has collections => (
   is => 'rw',
 );

=item launch

Méthode devant être implémentée dans tous les imports.

=cut
sub launch
{
    croak "'launch' method not implemented in " . ref(shift);
}

=item feed_collections

Méthode permettant d'envoyer les données aux collections à qui elles sont
destinées.

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
