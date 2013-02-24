package Classify::Display::Import;
use parent Classify::Display;

use strict;
use warnings;

use Moo;

has window => (
   is => 'rw',
 );

has progress_bar => (
   is => 'rw',
 );

has test => (
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

    my $window = Classify::Display::set_new_window(
        'Import', sub { $self->stop; });
    $window->add($self->init);


   $self->window($window);
}

=item $obj->init(NAME)

Permet d'initialiser l'affichage.

=cut
sub init
{
    my($self, $name) = @_;

    my $box = Gtk2::VBox->new(0, 0);

    my $progress_bar = Classify::Display::set_progress_bar;
    $self->progress_bar($progress_bar);

    # initialisation de la barre de progression
    $box->pack_start($progress_bar, 0 , 0, 0);
    $box->show();

    return Classify::Display::set_cadre($name, $box);
}

=item $obj->start()

Permet de lancer l'affichage.

=cut
sub start
{
    my $self = shift;

    $self->window->show_all;
}

=item $obj->update(TEXT, PERCENTAGE)

Permet de mettre à jour l'affichage.

=cut
sub update
{
    if (defined(my $progress_bar = shift->progress_bar))
    {
        $progress_bar->set_text(shift);
        $progress_bar->set_fraction(shift);
    }
}

=item $obj->stop()

Permet de stopper l'affichage et d'appeler la commande stop générale.

=cut
sub stop
{
    my $self = shift;

    $self->on_stop->();
}

1;
__END__
