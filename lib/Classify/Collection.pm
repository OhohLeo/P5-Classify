
package Classify::Collection;
use parent Classify::Base;

use Carp;

use Moo;

use Data::Dumper;

has name => (
   is => 'rw',
 );

has researches => (
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

    $self->researches({});
    $self->imported({});
    $self->classified({});
    $self->websites([]);

    return $self;
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

=item $obj->delete

Remove all possible timers.

=cut
sub delete
{
}

=item clean_before_saving

Clean collection before saving.

=cut
sub clean_before_saving
{
    shift->handle_result(undef);
}

=item $obj->get_info

Return a string that display all collection informations.

=cut
sub get_info
{
    my $self = shift;

    my $info = "\n\tresearches = ";

    # we enumerate researches handled by the collection
    my $count = keys %{$self->researches};
    if ($count)
    {
	while (my($name, undef) = each %{$self->researches})
	{
	    $info .= (--$count > 0) ? "$name, " : $name;
	}
    }
    else
    {
	$info .= 'none!';
    }

    $info .= "\n\twebsites = ";

    # we enumerate websites handled by the collection
    $count = @{$self->websites};
    if ($count)
    {
	foreach my $web (@{$self->websites})
	{
	    $info .= ($count-- > 0) ? ref $web . ', ' : ref $web;
	}
    }
    else
    {
	$info .= 'none!';
    }

    return "$info\n";
}

1;
__END__

