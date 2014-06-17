package Classify::Collections;

use strict;
use warnings;

use Storable;
use File::Find;
use Carp;
use Moo;

use Classify::Tools 'get_list';
use Classify::Collection::Cinema;

has input => (
    is => 'rw',
 );

has collections => (
    is => 'rw',
 );

has websites => (
    is => 'rw',
 );

has classify => (
    is => 'rw',
);

use constant
{
    STORE_COLLECTIONS => 'var/collections',
};

=head2 METHODS

=over 4

=item BUILD

Retreive collections if they exist & initialize display if needed.

=cut
sub BUILD
{
    my $self = shift;

    # collections initialisation
    $self->collections(eval "retrieve(STORE_COLLECTIONS)" // {});
}

=item $obj->create_collection_from_type(TYPE, [ INIT => ARGS, ... ])

=cut
sub create_collection_from_type
{
    shift->classify->create_object_from_type(
	'Collection', @_);
}

=item $obj->add(NAME, TYPE, WEBSITE, [ WEBSITE, ... ])

We create a new collection based on the I<TYPE> choosed with I<NAME>
and specified I<WEBSITE>s.

=cut
sub add
{
    my($self, $name, $type, @websites) = @_;

    # we check if collection name already exists
    if ($self->get($name))
    {
        $self->classify->log_warn("Collection '$name' already exists");
        return;
    }

    # we create the new collection & set the websites
    my $collection = $self->create_collection_from_type(
	$type,
	name     => $name,
        websites => @websites > 0 ? @websites : undef);

    # we store the new collection
    $self->collections->{$name} = $collection;

    # we store it
    $self->save;

    return $collection;
}


=item $obj->get(NAME [, NAME])

I<NAME>s are the name of the collections searched.

Return in all cases an array reference containing collections specified, undef
if one of the references has not been found.

=cut
sub get
{
    my $self = shift;

    my @collections;
    foreach my $name (@_)
    {
        push(@collections, $self->collections->{$name} // return undef);
    }

    return (wantarray ? @collections : $collections[0]);
}

=item $obj->get_by_type(TYPE)

Return in all cases an array reference containing collections with type
specified, undef if no references has been found.

=cut
sub get_by_type
{
   my($self, $type) = @_;

   my @collections;

   while (my(undef, $collection) = each %{$self->collections})
   {
       push(@collections, $collection)
           if ref $collection eq "Classify::Collection::$type";
   }

   return (wantarray ? @collections : $collections[0]);
}

=item $obj->clean(NAME [, NAME])

Clean I<NAME> collection content.

=cut
sub clean
{
    my $self = shift;

    foreach my $name (@_)
    {
	# we clean all data informations
	($self->get($name) // next)->clean;
    }

    # we store it
    $self->save;
}

=item $obj->delete(NAME[, NAME])

Delete I<NAME> collection & stop all process linked to this collection.

=cut
sub delete
{
    my $self = shift;

    foreach my $name (@_)
    {
	# we delete the collection from the collection list
	my $collection = (delete $self->collections->{$name}) // next;

	# we stop all process linked with this current collection
	$collection->delete
    }

    # we store it
    $self->save;
}

=item $obj->save

Save all collections.

=cut
sub save
{
    my $self = shift;

    my %collections = %{$self->collections};

    while (my(undef, $collection) = each %collections)
    {
	$collection->clean_before_saving;
    }

    store($self->collections, STORE_COLLECTIONS);
}

=item $obj->info(ALL)

Return string list of collection infos found.

If I<ALL> flag is set to one, you will receive all existing collections & the
generic one, otherwise you will only receive generic collections.

=cut
sub info
{
    my $self = shift;

    my $result;

    if (defined shift)
    {
	if (%{$self->collections})
	{
	    $result .= "Collection List :\n";

	    while (my($name, $collection) = each(%{$self->collections}))
	    {
		$result .= " - $name :" . $collection->get_info;
	    }
	}
	else
	{
	    $result .= "No Collection Found!\n";
	}
    }

    $result .= "\nGeneric Collection :\n";

    my $list = get_list('Collection');
    while (my($name, $class) = each %$list)
    {
        eval "require $class";
        die $@ if $@;
        $result .= " - $name : " . $class->info . "\n";
    }

    return $result;
}

1;
__END__
