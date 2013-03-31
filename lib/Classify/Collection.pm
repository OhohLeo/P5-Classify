package Classify::Collection;
use parent Classify::Base;

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

has color => (
   is => 'rw',
 );

has position => (
   is => 'rw',
 );

has handle_result  => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item BUILD

=cut
sub BUILD
{
    my $self = shift;

    $self->classified({});
    $self->imported({});

    return $self;
}

=item $obj->set_color(GDK_COLOR)

Set collection 16-bit RGB values.

=cut
sub set_color
{
    my($self, $color) = @_;

    $self->color([ $color->blue, $color->green, $color->red, $color->pixel ]);
}

=item $obj->get_info

Return a string that display all collection informations.

=cut
sub get_info
{
    my $self = shift;

    return "\n Web : none!\n" unless defined $self->websites;

    my $result;
    $result .= "\nWeb : ";

    foreach my $web ($self->websites)
    {
        $result .= ref $web . ", ";
    }

    return $result;
}

=item $obj->input(INPUT)

Handle here input data.

=cut
sub input
{
    my $self = shift;

    $self->warn("In collection '" . ref($self) . "', data not handled :\n"
                . Dumper(shift));
}

=item $obj->web_search(INPUT, FORCE)

Handle here input data.

=cut
sub web_search
{
    my($self, $input, $force) = @_;

    my $search = web_format($input->get('req') // $input->get('name'));

    my $inc = 0;

    my @websites = $self->websites;

    foreach my $web (@websites)
    {
        my $name = lc substr(ref $web, 15);

        $web->req(
            $search,
            sub
            {
                $self // return;

                $input->set('web_' . $name, shift);

                # we received all the data : search is now over
                if (@websites == ++$inc)
                {
                    $self->handle_result->($input)
                        if defined $self->handle_result;
                }
            });
    }
}

=item web_format

Return formated web request.

=cut
sub web_format
{
    my $search = shift;

    $search =~ s/^ //g;
    $search =~ s/ $//g;
    $search =~ s/  / /g;
    $search =~ s/ /+/g;

    return lc $search;
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

=item clean_before_saving

Clean collection before saving.

=cut
sub clean_before_saving
{
    my $self = shift;

    $self->classify(undef);
    $self->handle_result(undef);
}

=item restore(CLASSIFY)

Restore collection after saving.

=cut
sub restore
{
    my($self, $classify) = @_;

    $self->classify($classify);
}

1;
__END__

