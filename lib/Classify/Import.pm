package Classify::Import;
use parent Classify::Base;

use strict;
use warnings;

use Carp;

use Moo;

has filter => (
   is => 'rw',
 );

has researches => (
   is => 'rw',
);

has nb => (
   is => 'rw',
 );

has on_output => (
   is => 'rw',
 );

has on_stop => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item $obj->start()

Method that start analyse : must be implemented.

=cut
sub start
{
    croak "'launch' method not implemented in " . ref(shift);
}

=item $obj->stop()

=cut
sub stop
{
    (shift->on_stop // return)->();
}

=item $obj->count()

Method that count the number of elements expected : not mandatory.

=cut
sub count
{
}

=item $obj->output(DATA)

Method to output new encapsulate data in the classify system.

=cut
sub output
{
    my($self, $data) = @_;

    ($self->on_output // return)->($data);
}

1;
__END__
