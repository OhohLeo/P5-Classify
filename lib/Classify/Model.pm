package Classify::Model;

use strict;
use warnings;

use feature qw(say switch);

use Moo;

 has data => (
   is => 'rw',
 );

use Data::Dumper;

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

=item get(NAME, ...)

Get the value of I<NAME> from data

=cut
sub get
{
    my $self = shift;

    my @ret;
    foreach my $name (@_)
    {
        push(@ret, $self->data->{$name} // undef);
    }

    return @ret;
}

=item set(NAME, VALUE, [ NAME, VALUE ], ...)

Set the I<VALUE> for I<NAME> in data.

=cut
sub set
{
    my $self = shift;

    my $ret = 1;
    while (my($name, $value) = splice(@_, 0, 2))
    {
        if ($name eq 'type')
        {
            $self->check_type($value) // next;
            undef $ret;
        }

        $self->data->{$name} = $value;
    }

    return $ret;
}

=item set_after(NAME, VALUE, [ VALUE, ] ...)

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
                return $data->set_after($name, @_);
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

=item check

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

=item check_type(TYPE)

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

=item merge(MODEL)

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

sub type_generic
{
    return qw(name url);
}

sub type_file
{
    return qw(name url path extension);
}

sub type_directory
{
    return type_generic();
}

sub type_star
{
    return type_generic();
}

sub type_image
{
    return type_generic();
}

sub type_movie
{
    return type_generic();
}

sub type_character
{
    return type_generic();
}

1;
__END__

