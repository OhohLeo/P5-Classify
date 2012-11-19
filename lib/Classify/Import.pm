package Classify::Import;
use parent Classify::Base;

use strict;
use warnings;

use Carp;

use Moo;

use Classify::Display::Import;

has path => (
   is => 'rw',
 );

has on_output => (
   is => 'rw',
 );

has display => (
   is => 'rw',
 );

has on_stop => (
   is => 'rw',
 );

has condvar => (
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

=item stop

=cut
sub stop
{
    my $self = shift;

    $self->on_stop->() if defined $self->on_stop;
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

=item set_display

=cut
sub set_display
{
    my $self = shift;

    my $display = Classify::Display::Import->new(@_);

    # we start the display
    $display->start;

    $self->display($display);

    return $display;
}

1;
__END__
