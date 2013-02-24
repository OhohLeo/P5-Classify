package Classify::Model;

use strict;
use warnings;

use feature qw(say switch);

use Moo;

 has data => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item $obj->BUILD

=cut
sub BUILD
{
    my($self, $input) = @_;

    # initialise the data hash
    $self->data({});

    # set the data with mandatories values
    $self->set(%$input) // return;

    # check the data is good
    $self->check;
}

=item $obj->get(NAME, ...)

Get the value of I<NAME> from data

=cut
sub get
{
    my $self = shift;

    # simple result
    return $self->data->{shift()} unless @_ > 1;

    # multiple results
    my @ret;
    foreach my $name (@_)
    {
        push(@ret, $self->data->{$name} // undef);
    }

    return @ret;
}

=item $obj->set(NAME, VALUE, [ NAME, VALUE ], ...)

Set the I<VALUE> for I<NAME> in data.

=cut
sub set
{
    my $self = shift;

    my $ret;
    while (my($name, $value) = splice(@_, 0, 2))
    {
        # check if name is not a regex
        return unless $name =~ /\w+/;

        if ($name eq 'type')
        {
            $self->check_type($value) // next;
            undef $ret;
        }

        $self->data->{$name} = $value;
        $ret = 1;
    }

    return $ret;
}

=item $obj->set_after(NAME, VALUE, [ VALUE, ] ...)

Set the I<VALUE> for I<NAME> in data.

=cut
sub set_after
{
    my($self, $name) = splice(@_, 0, 2);

    return $self->set($name, @_) if $name eq 'type';

    if (defined(my $data = $self->data->{$name}))
    {
        for (ref $data)
        {
            when ('HASH')
            {
                while (my($key, $value) = splice(@_, 0, 2))
                {
                    $data->{$key} = $value;
                }
            }

            when ('ARRAY')
            {
                push(@$data, @_);
            }

            when (/Classify::Model/)
            {
                $data->{$name} = [ $data, @_ ];
             }

            default
            {
                $self->data->{$name} = [ $data, @_ ]
            }
        }

        return;
    }

    $self->data->{$name} = @_ > 1 ? [ @_ ] : shift;

    return 1;
}

=item $obj->check

Check if all mandatory keys are filled for specified type.

=cut
sub check
{
    my $self = shift;

    my $data = $self->data;

    my $method = $self->check_type($self->data->{type}) // return;
    my $ret = 1;

   foreach my $mandatory ($self->$method)
    {
        unless (defined $data->{$mandatory})
        {
            say "this '$mandatory' key should be defined!";
            undef $ret;
            next;
        }
    }

    return $ret;
}

=item $obj->check_type(TYPE)

Check the specified type exists and return the method associated.

=cut
sub check_type
{
    my($self, $type) = @_;

    if (defined(my $method = $self->can("type_$type")))
    {
        return $method;
    }

    say "'$type' method should be defined!";
    return undef;
}

=item $obj->merge(MODEL)

Merge a model with another, check if there is no key conflict.

=cut
sub merge
{
    my($self, $model) = @_;

    while (my($name, $value) = each %{$model->data})
    {
        if (exists $self->data->{$name})
        {
            say "merge : conflict with '$name' between "
                . $model->get('type') . " and " . $model->get('type');
           next;
        }

        $self->data->{$name} = $value;
    }
}

=item info

Display model details.

=cut
sub info
{
    return get_info(shift->data);
}

=item get_info

Recursive method displaying model content.

=cut
sub get_info
{
    my $result = shift;
    my $info;

    for (ref $result)
    {
        when ('HASH')
        {
            while (my($key, $value) = each %$result)
            {
                $info .= "$key : " . get_info($value) . "\n";
            }

            return substr($info, 0, -1);
        }

        when ('ARRAY')
        {
            foreach my $value (@$result)
            {
                $info .= get_info($value) . " ";
            }

            return substr($info, 0, -1);
        }

        when (/Classify::Model/)
        {
            return $result->info;
        }

        default
        {
            return $result;
        }
    }
}

=item type_generic

=cut
sub type_generic
{
    return qw(name url);
}

=item type_file

=cut
sub type_file
{
    return qw(name url path extension);
}

=item type_directory

=cut
sub type_directory
{
    return type_generic();
}

=item type_star

=cut
sub type_star
{
    return type_generic();
}

=item type_image

=cut
sub type_image
{
    return type_generic();
}

=item type_movie

=cut
sub type_movie
{
    return type_generic();
}

=item type_character

=cut
sub type_character
{
    return type_generic();
}

1;
__END__

