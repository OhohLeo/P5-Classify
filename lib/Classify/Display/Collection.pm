package Classify::Display::Collection;

use strict;
use warnings;

use Moo;

has collection => (
    is => 'rw',
 );

has color => (
   is => 'rw',
 );

has position => (
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

=item $obj->get_name()

Return the name of the collection

=cut
sub get_name
{
    return shift->collection->name // 'unknown';
}

=item $obj->logo()

Return the logo format to display.

=cut
sub logo
{
    my $self = shift;

    Gtk2::Gdk::Rectangle->new(0, 0, 20, 20);
    Gtk2::Gdk::Rectangle->new(5, 5, 20, 20);
}

=item $obj->set_color(GDK_COLOR)

Set collection 16-bit RGB values.

=cut
sub set_color
{
    my($self, $color) = @_;

    $self->color([ $color->blue, $color->green, $color->red, $color->pixel ]);
}

1;
__END__
