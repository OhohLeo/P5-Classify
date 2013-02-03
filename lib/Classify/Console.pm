package Classify::Console;

use strict;
use warnings;

use AnyEvent;
use Moo;

use feature qw(say switch);

use Data::Dumper;

has to_classify => (
   is => 'rw',
 );

has analysing => (
   is => 'rw',
 );

has count => (
    is => 'rw',
 );

has result => (
   is => 'rw',
 );

has condvar => (
   is => 'rw',
 );

has watcher => (
   is => 'rw',
 );

has on_stop => (
   is => 'rw',
 );

=item launch

=cut
sub launch
{
    my $self = shift;

    # counter initialisation
    $self->count(0);

    # anyevent condvar initialisation
    $self->condvar(AnyEvent->condvar);

    $self->watcher(AnyEvent->io(
                       fh   => \*STDIN,
                       poll => 'r',
                       cb   => sub
                       {
                           $self // return;

                           # we check if we do accept user input
                           return unless defined $self->result;

                           chomp (my $input = <STDIN>);

                           return $self->stop if $input eq 'exit';

                           $self->result->($input);
                       }));
}

=item $obj->stop

=cut
sub stop
{
    my $self = shift;

    $self->watcher(undef);

    # we exit here if needed
    $self->on_stop->() if defined $self->on_stop;
}

=item $obj->on_input(COLLECTION, MODEL)

=cut
sub on_input
{
    my($self, $collection, $model) = @_;

    $self->to_classify([]) unless defined $self->to_classify;

    push($self->to_classify, $collection, $model);

    $self->count($self->count + 1);

    $self->on_next_model unless $self->analysing;
}

=item $obj->on_next_model

=cut
sub on_next_model
{
    my $self = shift;

    # we launch analyse process
    $self->analysing(1);

    unless (defined $self->to_classify)
    {
        say 'No more files to handle!';

        # analyse process is over
        $self->analysing(undef);

        # we exit here if needed
        $self->stop();

        return;
    }

    say 'Remaining ' . $self->count . ' file(s) to handle :';

    $self->handle_model(splice($self->to_classify, 0, 2));

    $self->count($self->count - 1);

    # no more files in the counter
    $self->to_classify(undef) if $self->count == 0;
}

=item $obj->handle_model(COLLECTION, MODEL)

=cut
sub handle_model
{
    my($self, $collection, $model) = @_;

    say "Classify for '" . $collection->name
        . "' collection :\n\t" . $model->get('name') . ":\n";

    # we handle best result found first
    if (defined(my $best_result = $model->get('best_result')))
    {
        # we set the result callback
        $self->result(
            sub
            {
                $self // return;

                for (shift)
                {
                    when (/y/)
                    {
                        $self->user_confirm;
                        return;
                    }

                    when (/n/)
                    {
                        $self->on_next_model;
                        return;
                    }

                    default
                    {
                        $self->user_websites;
                        return;
                    }
                }

                $self->user_websites;
            });

        # let user choose the result
        say "Accept this result? [y/n/] :";
        return;
    }

    $self->user_websites;
}

=item $obj->user_websites

=cut
sub user_websites
{
    my $self = shift;

    # we display web informations found
    my $count = 0;
    my $display = "WEBINFOS";


    # we set the result callback
    $self->result(
        sub
        {
            $self // return;

            for (shift)
            {
                when(/\d+/)
                {
                    $self->user_confirm;
                    return;
                }

                when (/n/)
                {
                    $self->on_next_model;
                    return;
                }

                default
                {
                    say "invalid input!";
                }
            }
        });

    say "$display\nEnter result : [0-$count/n] :";
    return;
}


=item $obj->user_confirm

=cut
sub user_confirm
{
    my $self = shift;

    # we set the result callback
    $self->result(
        sub
        {
            $self // return;

            for (shift)
            {
                when (/y/)
                 {
                     # we write the data
                     $self->on_next_model;
                     return;
                 }

                 when (/n/)
                 {
                     $self->on_next_model;
                     return;
                 }

                 default
                 {
                     $self->user_websites;
                     return;
                 }
            }
        });

    # we display the final info to write

    say "Confirm this result? [y/n/] :";
    return;
}

1;
