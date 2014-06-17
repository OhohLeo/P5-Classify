package Classify::Display::Import;
use parent Classify::Base;

use strict;
use warnings;

use AnyEvent 'timer';

use Moo;

use Scalar::Util;

has handle_import => (
   is => 'rw',
);

has waiting => (
    is => 'rw',
);

has window => (
   is => 'rw',
);

has progress_bar => (
   is => 'rw',
);

has nb => (
   is => 'rw',
);

has inc => (
   is => 'rw',
);

=head2 METHODS

=over 4

=item BUILD

Initialize Import Window.

=cut
sub BUILD
{
    my $self = shift;

    # we replace 'on_output' and 'on_stop' callback to handle display
    if (defined(my $import = $self->handle_import))
    {
	my($on_output, $on_stop) = ($import->on_output,
				    $import->on_stop);

	$import->on_output(
	    sub
	    {
		my $data = shift;

		# $self->update($data->research->name);
		# $on_output->($data);
	    });

	$import->on_stop(
	    sub
	    {
		$self->stop;
		$on_stop->();
	    });

	if (defined(my $on_recursive =
		    $import->can('on_recursive')))
	{
	    warn "ON RECURSIVE!";
	    $import->on_recursive(
		sub
		{
		    warn "HERE!";
		    AnyEvent->timer(
			after => 5,
			cb => $on_recursive);
		});
	}
    }

    my $window = $self->classify->set(
    	'window', 'Import', 0,
	sub
	{
	    $self->handle_import->stop;
	    $self->window(undef);
	});

    # on stocke la fenêtre
    $self->window($window);

    $window->resize(400, 100);
}


=item $obj->start()

Launch displayed import generic system.

=cut
sub start
{
    my $self = shift;

    warn "DISPLAY START!";

    my $box = Gtk2::VBox->new(0, 0);

    # we create a progress bar
    my $progress_bar = $self->classify->set('progress_bar');
    $self->progress_bar($progress_bar);

    # initialisation de la barre de progression
    $box->pack_start($progress_bar, 0 , 0, 0);

    # on affiche tout
    $progress_bar->show;

    $box->show();

    $self->window->add($box);

    # we show the new window
    $self->window->show_all;

    # we count the number of elements
    $self->count;

    # we launch import process
    $self->handle_import->start(@_, undef, $self->inc);
}

=item $obj->count()

Count number of elements to import.

=cut
sub count
{
    my $self = shift;

    $self->update("Wait for analyse...");

    $self->waiting(
	AnyEvent->timer(
	    after => 1,
	    cb => sub {
		warn "START";
		$self->classify->condvar->send;
		$self->handle_import->start(
		    @_, undef, $self->nb, 1);
	    }));

    $self->classify->condvar->recv;
}


=item $obj->update(TEXT, PERCENTAGE)

Permet de mettre à jour l'affichage.

=cut
sub update
{
    my $self = shift;

    if (defined(my $progress_bar = $self->progress_bar))
    {
        $progress_bar->set_text(shift);
        $progress_bar->set_fraction($self->inc / $self->nb)
	    if $self->nb;

	$progress_bar->show_now;
    }
}

=item $obj->stop()

Permet de stopper l'affichage et d'appeler la commande stop générale.

=cut
sub stop
{
    my $self = shift;

    $self->progress_bar(undef);
    $self->window(undef);
}

1;
__END__
