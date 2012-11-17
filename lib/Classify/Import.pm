package Classify::Import;
use parent Classify::Base;

use strict;
use warnings;

use Carp;

use Moo;

has path => (
   is => 'rw',
 );

has on_output => (
   is => 'rw',
 );

has display => (
   is => 'rw',
 );

has stop_now => (
   is => 'rw',
 );

has on_stop => (
   is => 'rw',
 );

=item launch

Méthode devant être implémentée dans tous les imports, permettant de lancer
l'analyse.

=cut
sub launch
{
    croak "'launch' method not implemented in " . ref(shift);
}

=item output

Méthode devant être implémentée dans tous les imports, permettant d'émettre les
données une fois analysées.

=cut
sub output
{
    if (defined(my $out = shift->on_output))
    {
        return $out->(@_);
    }
}

=item stop

=cut
sub stop
{
    my $self = shift;
    warn "HERE STOP!";
    $self->stop_now(1);
    $self->on_stop->() if defined $self->on_stop;
}

1;
__END__
