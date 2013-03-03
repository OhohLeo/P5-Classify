package Classify;

# ABSTRACT: Classify : simply manage your collections!

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;

use Classify::Traduction;
use Classify::Display::Main;

use Classify::Collection::Cinema;

use Classify::Web::IMDB;

use Data::Dumper;

use Term::ANSIColor qw(:constants);
use Class::Inspector;
use Storable;
use File::Find;
use Carp;
use Moo;

use feature 'say';

has condvar => (
   is => 'rw',
 );

has collections => (
   is => 'rw',
 );

has trad => (
   is => 'rw',
 );

has display => (
   is => 'rw',
 );

has save => (
   is => 'rw',
 );

has no_log => (
   is => 'rw',
 );

use constant
{
    STORE_CLASSIFY    => 'var/classify',
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

    # anyevent condvar initialisation
    $self->condvar(AnyEvent->condvar);

    # classify initialisation
    $self->save(eval "retrieve(STORE_CLASSIFY)" // {});

    # collections initialisation
    $self->collections(eval "retrieve(STORE_COLLECTIONS)" // {});

    # traduction initialisation
    $self->trad(Classify::Traduction::->new(
                    classify => $self,
                    language => $self->trad));

    # display initialisation
    if (defined $self->display)
    {
        $self->display(
            Classify::Display::Main::->new(
                classify => $self,
                on_stop => sub { $self->stop; }));
    }
}

=item $obj->start

=cut
sub start
{
    my $self = shift;

    $self->log_great("Classify is starting up.");

    # start display
    $self->display->start if defined $self->display;

    # start anyevent
    $self->condvar->recv;
}

=item $obj->clean

=cut
sub clean
{
    # collections cleaning
    shift->collections({});
}

=item $obj->stop

=cut
sub stop
{
    my $self = shift;

    # stop anyevent
    $self->condvar->send;

    # we store everything
    $self->save_collections;

    $self->log_great("Classify stopped.");
}

=item $obj->translate

=cut
sub translate
{
    return ((shift->trad // return)->translate(@_));
}

=item $obj->log

=cut
sub log
{
    my($self, $log) = @_;

    say $log unless defined $self->no_log;
}

=item $obj->log_great

=cut
sub log_great
{
    shift->log(GREEN . shift . RESET);
}

=item $obj->log_info

=cut
sub log_info
{
    shift->log(shift);
}

=item $obj->log_warn

=cut
sub log_warn
{
    shift->log(YELLOW . shift . RESET);
}

=item $obj->log_critic

=cut
sub log_critic
{
    shift->log(RED . shift . RESET);
}

=item $obj->get_collection(NAME)

=cut
sub get_collection
{
    return shift->collections->{shift // return};
}

=item $obj->get_collections(NAME, [ NAME ], ...)

I<NAMES> could be an array or a scalar.

Return in all cases an array reference containing collections specified, undef
if no references has been found.

=cut
sub get_collections
{
    my $self = shift;

    my @collections;
    foreach my $collection (@_)
    {
        push(@collections, $self->get_collection($collection));
    }

    return @collections;
}

=item $obj->get_collections_by_type(TYPE)

Return in all cases an array reference containing collections with type
specified, undef if no references has been found.

=cut
sub get_collections_by_type
{
   my($self, $type) = @_;

   my @collections;

   while (my(undef, $collection) = each %{$self->collections})
   {
       push(@collections, $collection)
           if ref $collection eq "Classify::Collection::$type";
   }

   return @collections;
}

=item $obj->set_collection(NAME, TYPE, WEBSITE, [ WEBSITE, ... ])

We create a new collection based on the I<TYPE> choosed with I<NAME>
and specified I<WEBSITE>s.

=cut
sub set_collection
{
    my($self, $name, $type, @websites) = @_;

    # we check if collection name already exists
    if (defined $self->get_collection($name))
    {
        $self->log_warn("Collection '$name' already exists");
        return;
    }

    # we create the new collection & set the websites
    my $collection = $self->get_new_object_from_type('Collection', $type,
        classify => $self,
        name => $name,
        websites => @websites > 0 ? @websites : undef);

    # we store the new collection
    $self->collections->{$name} = $collection;

    # we store it
    $self->save_collections;

    return $collection;
}

=item $obj->display_set_collection

Graphical way to create a new collection.

=cut
sub display_set_collection
{
    my($self, $cb) = @_;

    return ($self->display // return)->menu_new_collection->($cb);
}

=item $obj->clean_collection(NAME)

Delete I<NAME> collection & stop all process linked to this collection.

=cut
sub clean_collection
{
    my($self, $name) = @_;

    # we get the new collection
    my $collection = $self->get_collection($name) // return;

    # we clean all data informations
    $collection->clean;

    # we store it
    $self->save_collections;

    return $collection;
}

=item $obj->delete_collection(NAME)

Delete I<NAME> collection & stop all process linked to this collection.

=cut
sub delete_collection
{
    my($self, $name) = @_;

    # we delete the collection from the collection list
    my $collection = delete $self->collections->{$name};

    # we stop all process linked with this current collection
    # $collection->delete

    # we store it
    $self->save_collections;

    return $collection;
}

=item $obj->save_collections

Save all collections.

=cut
sub save_collections
{
    my $self = shift;

    my %collections = %{$self->collections};

    while (my(undef, $collection) = each %collections)
   {
       $collection->clean_before_saving;
   }

    store($self->collections, STORE_COLLECTIONS);

   while (my(undef, $collection) = each %collections)
   {
       $collection->restore($self);
   }
}

=item $obj->save_classify

Save specific params.

=cut
sub save_classify
{
    my($self, $key, $value) = @_;

    $self->save->{$key} = $value;

    store($self->save, STORE_CLASSIFY);
}

=item $obj->info_collections(ALL)

Return string list of collection infos found.

If I<ALL> flag is set to one, you will receive all existing collections & the
generic one, otherwise you will only receive generic collections.

=cut
sub info_collections
{
    my $self = shift;

    my $result;

    if (defined shift)
    {
        $result .= "Existing Collection : \n";
        $result .= " none!\n" unless %{$self->collections};
        while (my($name, $collection) = each(%{$self->collections}))
        {
            $result .= " - $name : " . $collection->get_info;
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

=item $obj->set_import(IMPORT_NAME, COLLECTIONS, [ INIT => ARGS, ... ])

=cut
sub set_import
{
    my($self, $name, $collections) = splice(@_, 0, 3);

    my $import = $self->get_new_object_from_type('Import', $name, @_);

    $import->on_output(
        sub
        {
            shift;

            foreach my $collection ($self->get_collections(@$collections))
            {
                $collection->input(@_);
            }
        });


    return $import;
}

=item $obj->set_export(COLLECTION, IMPORT_NAME, [ INIT => ARGS, ... ])

=cut
sub set_export
{
    my($self, $collections, $name) = splice(@_, 0, 3);

    my $export = $self->get_new_object_from_type('Export', $name, @_);

    foreach my $collection ($self->get_collections(@$collections))
    {
        (defined $collection->exports) ?
            push(@{$collection->exports}, $export)
            : $collection->exports([ $export ]);
    }

    return $export;
}

=item $obj->get_new_object_from_type(PLUGIN_DIRECTORY, TYPE,
    [ INIT => ARGS, ... ])

Return new instance of the object with specified type

=cut
sub get_new_object_from_type
{
    my($self, $plugin, $type) = splice(@_, 0, 3);

    croak "No '$plugin' directory found!"
        unless -d "lib/Classify/$plugin";

    my $class = "Classify::$plugin\::$type";

    eval "require $class";
    die $@ if $@;

    return $class->new('classify' => $self, @_);
}

=item check_type(PLUGIN_DIRECTORY, TYPE)

Return 1 if the specified type with the plugin choosed exists, undef otherwise.

=cut
sub check_type
{
    my($plugin, $type) = @_;

    return undef unless -d "lib/Classify/$plugin";

    my $class = "Classify::$plugin\::$type";

    eval "require $class";
    die $@ if $@;

    return $@ ? undef : 1;
}

=item get_list(PLUGIN_DIRECTORY)

Return hash specifying list of plugins found :
{ 'plugin name' => 'plugin path' }.

=cut
sub get_list ($)
{
    my $plugin = ucfirst shift;

    my %store;

    finddepth(sub
         {
             my $name = $_;

             $name =~ s/\.pm$//;

             $store{$name} = "Classify::$plugin\::$name"
                 if (-f $_);

         }, "lib/Classify/$plugin");

    return \%store;
}

=item get_info(CLASS, WITH_URL)

Return string list of websites infos found.

=cut
sub get_info
{
    my $list = get_list(shift);
    my $with_url = shift;
    my $result;
    while (my($name, $class) = each %$list)
    {
        eval "require $class";
        die $@ if $@;

        $result .= " - $name : "
            . ($with_url ? $class->url : '')
            . $class->info . "\n";
    }

    return $result;
}

1;
__END__
