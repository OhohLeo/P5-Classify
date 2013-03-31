package Classify::Display::Collection;
use parent Classify::Display;

use strict;
use warnings;

use Moo;

has color => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item BUILD(COLOR)

=cut
sub BUILD
{
    my $self = shift;

    $self->color(shift);
}

=item $obj->logo

=cut
sub logo
{
    my $self = shift;

    Gtk2::Gdk::Rectangle->new(0, 0, 20, 20);
    Gtk2::Gdk::Rectangle->new(5, 5, 20, 20);


}

1;
__END__
