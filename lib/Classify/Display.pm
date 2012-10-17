package Classify::Display;

use strict;
use warnings;

use Gtk2::SimpleMenu;
use Data::Dumper;

use Moo;

use feature 'switch';

has trad => (
   is => 'rw',
 );

has on_stop => (
   is => 'rw',
 );

=item $obj->set(METHOD_NAME, PATH, NAME, DATA, [ NAME, DATA ] ...)

Permet de cr�er un menu en fonction de param�tres.

=cut
sub set
{
    my($self, $method_name) = splice(@_, 0, 2);

    if (defined(my $method = $self->can("set_$method_name")))
    {
        return $method->($self->trad->translate(@_));
    }
}

=item $obj->set_menu_bar(NAME, DATA, [ NAME, DATA ] ...)

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

        my $menu = Gtk2::Menu->new() ;

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

1;

