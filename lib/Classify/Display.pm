package Classify::Display;
use parent Classify::Base;

use strict;
use warnings;

use Gtk2::SimpleMenu;
use Data::Dumper;

use Moo;

use feature 'switch';

has on_stop => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item $obj->set(METHOD_NAME, PATH, NAME, DATA, [ NAME, DATA ] ...)

Permet de cr�er un menu en fonction de param�tres.

=cut
sub set
{
    my($self, $sheet_name, $method_name) = splice(@_, 0, 3);

    if (defined(my $method = $self->can("set_$method_name")))
    {
        return $method->($self->classify->translate($sheet_name, @_));
    }
}

=item set_menu_bar(NAME, DATA, [ NAME, DATA ] ...)

Permet de cr�er un menu en fonction de param�tres.

I<NAME> est le nom du menu et le suivant est une r�f�rence vers un tableau
contenant le nom du sous-menu et son callback � appeler.

=cut
sub set_menu_bar
{
    my $menu_bar = Gtk2::MenuBar->new();

    while (@_)
    {
        my($name, $data) = splice(@_, 0, 2);

        my $menu = Gtk2::Menu->new();

        while (@$data)
        {
            my($item_name, $cb) = splice(@$data, 0, 2);
            my $menu_item = Gtk2::MenuItem->new_with_label($item_name) ;
            $menu->append($menu_item) ;
        }

        my $main_title = Gtk2::MenuItem->new_with_label($name);
        $main_title->set_submenu($menu);
        $menu_bar->append($main_title);
    }

    return $menu_bar;
}

=item set_cadre(NAME, BOX_TO_PUT_INSIDE)

Permet de cr�er un cadre pouvant contenir une box.

I<NAME> est le nom du cadre.

=cut
sub set_cadre
{
    my $cadre = Gtk2::Frame->new(shift);

    $cadre->add(shift);

    $cadre->show;

    return $cadre;
}

=item set_progress_bar(NAME, BOX_TO_PUT_INSIDE)

Permet de cr�er un cadre pouvant contenir une box.

I<NAME> est le nom du cadre.

=cut
sub set_progress_bar
{
    my $progress_bar = Gtk2::ProgressBar->new();

    $progress_bar->set_text('progress bar');
    $progress_bar->show;

    return $progress_bar;
}

=item set_new_window(NAME, DESTROY_CB)

Permet de cr�er une nouvelle fen�tre.

I<NAME> est le nom de la nouvelle fen�tre.

=cut
sub set_new_window
{
    my $window = Gtk2::Window->new;

    $window->set_title(shift);
    $window->signal_connect(destroy => shift);

    return $window;
}

1;

