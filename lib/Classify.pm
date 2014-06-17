package Classify;

# ABSTRACT: Classify : simply manage your collections!

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;

use Data::Dumper;

use Term::ANSIColor qw(:constants);
use Storable;
use Carp;
use Moo;

use Classify::Collections;
use Classify::Traduction;

use Classify::Web::IMDB;

use Classify::Tools qw(check_type get_info get_list);

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

has saved => (
   is => 'rw',
 );

has no_log => (
   is => 'rw',
 );

use constant
{
    STORE_CLASSIFY => 'var/classify',
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

    # classify initialisation parameters
    $self->saved(eval "retrieve(STORE_CLASSIFY)" // {});

    # traduction initialisation
    $self->trad(Classify::Traduction::->new(
                    classify => $self,
                    language => $self->trad));

    # collections initialisation
    $self->set_collections;
}

=item $obj->start

=cut
sub start
{
    my $self = shift;

    $self->log_great("Classify is starting up.");

    # start anyevent
    $self->condvar->recv;
}

=item $obj->stop

=cut
sub stop
{
    my $self = shift;

    # stop anyevent
    $self->condvar->send;

    # we store everything
    $self->collections->save;

    $self->log_great("Classify stopped.");
}

=item $obj->translate

=cut
sub translate
{
    return ((shift->trad // (return @_))->translate(@_));
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

=item $obj->save(KEY => VALUE)

Save specific params.

=cut
sub save
{
    my($self, $key, $value) = @_;

    $self->saved->{$key} = $value;

    store($self->saved, STORE_CLASSIFY);
}

=item $obj->set_collections()

Initialise collections : needed to choose properly between
I<Classify::Collections> or I<Classify::Display::Collections>.

=cut
sub set_collections
{
    my $self = shift;

    # collections initialisation
    $self->collections(Classify::Collections::->new(
			   classify => $self));
}

=item $obj->set_import(IMPORT_NAME, COLLECTIONS, [ INIT => ARGS, ... ])

=cut
sub set_import
{
    my($self, $name, $collections) = splice(@_, 0, 3);

    my $import = $self->create_object_from_type('Import', $name, @_);

    $import->on_output(
        sub
        {
            shift;

            foreach my $collection ($self->collections->get(@$collections))
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

    my $export = $self->create_object_from_type('Export', $name, @_);

    foreach my $collection ($self->collections->get(@$collections))
    {
        (defined $collection->exports) ?
            push(@{$collection->exports}, $export)
            : $collection->exports([ $export ]);
    }

    return $export;
}

=item $obj->create_object_from_type(PLUGIN_DIRECTORY, TYPE,
    [ INIT => ARGS, ... ])

Return new instance of the object with specified type

=cut
sub create_object_from_type
{
    my($self, $plugin, $type) = splice(@_, 0, 3);

    croak "No '$plugin' directory found!"
        unless -d "lib/Classify/$plugin";

    my $class = "Classify::$plugin\::$type";

    eval "require $class";
    die $@ if $@;

    return $class->new('classify' => $self, @_);
}

1;
__END__
