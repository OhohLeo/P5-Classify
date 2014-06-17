package Classify::Research;

use feature qw(say switch);

use Scalar::Util;
use Moo;

has name => (
   is => 'rw',
 );

has data_types => (
    is => 'ro',
);

has responses => (
    is => 'ro',
);

has similarities_threshold => (
    is => 'ro',
);

has responses_max_number => (
    is => 'ro',
);

our @SUPPORTED_DATA_TYPES = qw(text markup int double bool scalar pixbuf);
our %REPLACED_DATA_TYPES = (
    'directory' => 'text',
    'file'      => 'text',
    );


=head2 METHODS

=over 4

=item BUILD

We check that I<data_types> is correctly initialised.

=cut
sub BUILD
{
    my $self = shift;

    while(my($name, $type) = each(%{$self->data_types // return}))
    {
	# the type could be another research
	next if $type =~ /^research_\w+$/;

	# we eventually replace
	$type = $REPLACED_DATA_TYPES{$type} // $type;

	# otherwise it should be one of the supported data types
	unless ($type ~~ @SUPPORTED_DATA_TYPES)
	{
	    die "unsupported data type '$type' in the research " . $self->name;
	}
    }
}

=item $obj->new_data(NAME => VALUE, ...)

It returns a new created I<Classify::Data> containing all the
I<DATA_VALUES> accepted by the research.

=cut
sub new_data
{
    my $data = Classify::Data->new(research => shift);

    # we check that the value respect the type fixed
    while(my($name, $value) = splice(@_, 0, 2))
    {
	$data->set($name, $value);
    }

    return $data;
}

=item $obj->set_response(DATA, NAME => VALUE, ...)

=cut
sub set_response
{
    my $data = Classify::Data->new(research => shift);

    # we check that the value respect the type fixed
    while(my($name, $value) = splice(@_, 0, 2))
    {
	$data->set($name, $value);
    }

    # we check t
}

=item $obj->validate_value(NAME, VALUE)

We check that the I<VALUE> is conformed to the type associated with
I<NAME>.

=cut
sub validate_value
{
    my($self, $name, $value) = @_;

    return unless defined $value;

    for ($self->data_types->{$name})
    {
	when ('file')
	{
	    return 1 if -f $value;
	}

	when ('directory')
	{
	    return 1 if -d $value;
	}

	when ([ 'text', 'scalar' ])
	{
	    return 1 if $value =~ /^[\w|\s]+$/;
	}

	when ('markup')
	{
	}

	when ('int')
	{
	    return 1 if $value =~ /^-?\d+$/;
	}

	when ('double')
	{
	}

	when ('bool')
	{
	    return 1 if $value == 0 or $value == 1;
	}

	when ('pixbuf')
	{
	}
    }

    return undef;
}


package Classify::Data;

use Moo;

has research => (
   is => 'ro',
 );

has infos => (
   is => 'rw',
 );

=item BUILD

We initialise the I<infos> data container.

=cut
sub BUILD
{
    shift->infos({});
}

=item $obj->get(NAME, ...)

Get the value of I<NAME> from data

=cut
sub get
{
    my $self = shift;

    # simple result
    return $self->infos->{shift()} unless @_ > 1;

    # multiple results
    my @ret;
    foreach my $name (@_)
    {
        push(@ret, $self->infos->{$name} // undef);
    }

    return @ret;
}

=item $obj->set(NAME, VALUE, [ NAME, VALUE ], ...)

Set the I<VALUE> for I<NAME> in data.

=cut
sub set
{
    my $self = shift;

    while (my($name, $value) = splice(@_, 0, 2))
    {
        # we validate the name and the format
        next unless defined $self->research->validate_value($name, $value);

	# we store the new value
        $self->infos->{$name} = $value;
    }
}

=item $obj->set_after(NAME, VALUE, [ VALUE, ] ...)

Set the I<VALUE> for I<NAME> in data.

=cut
sub set_after
{
    my($self, $name) = splice(@_, 0, 2);

    my @accepted;

    # we check the received values
    foreach my $value (@_)
    {
        # we validate the name and the format
        next unless defined $self->research->validate_value($name, $value);

	push(@accepted, $value);
    }

    # we get the value associated to the name
    my $infos = $self->infos->{$name};

    # we check if a data already exists at these name
    unless (defined $infos)
    {
	$self->infos->{$name} = @accepted > 1 ? \@accepted : shift @accepted ;
    }

    for (ref $infos)
    {
	when ('ARRAY')
	{
	    $infos = [ @$infos, @accepted ];
	}

	when (/Classify::Data/)
	{
	    $infos->{$name} = [ $infos, @accepted ];
	}

	default
	{
	    $self->infos->{$name} = [ $infos, @_ ]
	}
    }
}

=item $obj->merge(RESEARCH)

Merge a research with another, check if there is no key conflict.

=cut
sub merge
{
    my($self, $data) = @_;

    while (my($name, $value) = each %{$self->infos})
    {
        if (exists $self->infos->{$name})
        {
            say "merge : conflict with '$name' between "
                . $data->get('type') . " and " . $data->get('type');
           next;
        }

        $self->infos->{$name} = $value;
    }
}

=item info

Display data details.

=cut
sub info
{
    my $self = shift;

    my $info = 'type: ' . $self->research->name . "\n";

    while (my($name, $value) = each %{$self->infos})
    {
	$info .= " - $name : " . get_data($value) . "\n";
    }

    return $info // 'none';
}

=item get_data

Recursive method displaying research content.

=cut
sub get_data
{
    my $result = shift;
    my $info;

    for (ref $result)
    {
        when ('ARRAY')
        {
            foreach my $value (@$result)
            {
                $info .= get_info($value) . " ";
            }

            return substr($info, 0, -1);
        }

        when (/Classify::Data/)
        {
            return $result->info;
        }

        default
        {
            return $result;
        }
    }
}

1;
__END__

