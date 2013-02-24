package Classify::Display::Main;
use parent Classify::Display;

use strict;
use warnings;

use Moo;

use Data::Dumper;

use Gtk2 '-init';

has window => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item $obj->BUILD()

Initialize main Window.

=cut
sub BUILD
{
    my $self = shift;

    my $window = Classify::Display::set_new_window(
        'Classify',
        sub { $self->stop; });
   $window->add($self->init);

   $self->window($window);
}

=item $obj->init()

Permet d'initialiser l'affichage.

=cut
sub init
{
    my $self = shift;

    my $box = Gtk2::VBox->new(0, 0);

    # initialisation de la barre de menu
    $box->pack_start($self->menu_bar, 0 , 0, 0);

    # initialisation de la barre des collections
    #$box->pack_start($self->menu_bar, 0 ,0, 0);

    $box->show();
    return $box;
}

=item $obj->start()

Permet de lancer l'affichage.

=cut
sub start
{
    my $self = shift;

    $self->window->show_all;
    Gtk2->main;
}

=item $obj->stop()

Permet de stopper l'affichage et d'appeler la commande stop générale.

=cut
sub stop
{
    my $self = shift;

    Gtk2->main_quit;

    $self->on_stop->();
}

=item $obj->set(METHOD_NAME, PATH, NAME, DATA, [ NAME, DATA ] ...)

Permet de créer un menu en fonction de paramètres.

=cut
sub set
{
    return shift->SUPER::set('Classify', @_);
}

=item $obj->menu_bar()

Permet d'afficher la barre des menus

=cut
sub menu_bar
{
    my $self = shift;

    return $self->set(
        'menu_bar',
        'MenuFile', [ 'MenuImport', 'toto', 'MenuExport', 'toto' ],
        'MenuEdit', [],
        'MenuConfiguration', []),
}

=item $obj->collections_bar()

Permet d'afficher la barre des collections

=cut
sub collections_bar
{

}

1;
__END__

