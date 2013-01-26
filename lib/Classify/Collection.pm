package Classify::Collection;

use strict;
use warnings;

use Carp;

use Moo;

use Data::Dumper;

has name => (
   is => 'rw',
 );

has imported => (
   is => 'rw',
 );

has classified => (
   is => 'rw',
 );

has websites => (
   is => 'rw',
 );

=item BUILD

=cut
sub BUILD
{
    my $self = shift;

    $self->classified({});
    $self->imported({});
    $self->websites([]);

    return $self;
}

=item info

Return a string that display all specific collection informations.

=cut
sub info
{
    croak "'info' method should be defined in " . ref shift;
}

=item $obj->get_info

Return a string that display all collection informations.

=cut
sub get_info
{
    my $self = shift;

    my $result;
    $result .= "\nWeb : ";
    $result .= "none!\n" unless @{$self->websites};
    foreach my $web (@{$self->websites})
    {
        $result .= ref $web . ", ";
    }

    return $result;
}

=item $obj->input

Handle here input data.

=cut
sub input
{
    warn "In collection '" . ref(shift) . "', data not handled :\n"
        . Dumper(shift);
}

=item $obj->clean

Remove all informations contained inside the collection.

=cut
sub clean
{
    my $self = shift;

    $self->classified({});
    $self->imported({});
}

1;
__END__

