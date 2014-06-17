package Classify::Display::SimpleList;
use parent Classify::Display;

use strict;
use warnings;

use Moo;

has list => (
   is => 'rw',
 );

sub BUILD
{
    my $self = shift;

    $self->list(Gtk2::SimpleList->new(@_));
}

1;
__END__
