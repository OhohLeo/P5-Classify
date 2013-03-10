package Classify::Display::Main;
use parent Classify::Display;

use strict;
use warnings;

use Moo;

use Classify;

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

    my $window = $self->set('window', 'ApplicationName', 0,
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

    # initialisation de la barre des logs

    # initialisation de la barre des collections
    #$box->pack_start($self->menu_bar, 0 ,0, 0);

    $box->show;
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

=item $obj->translate(DATA ...)

Return I<DATA> translate.

=cut
sub translate
{
    return shift->SUPER::translate('Classify', @_);
}

=item $obj->menu_bar()

Display bar menu.

=cut
sub menu_bar
{
    my $self = shift;

    return $self->set(
        'menu_bar',
        'MenuFile', [ 'MenuNewCollection', $self->menu_new_collection,
                      'MenuImport', sub {},
                      'MenuExport', sub {},
                      'MenuLeave', sub { $self->stop; }],
        'MenuConfiguration', []),
}

=item $obj->menu_new_collection()

Display new collection menu.

=cut
sub menu_new_collection
{
    my $self = shift;

    return sub
    {
        my $cb = shift;

        $self // return;

        my $window = $self->set('window', 'MenuNewCollection', 10,
                                ref $cb eq 'CODE' ? $cb : undef);

        my $box = Gtk2::VBox->new(1, 2);

        # enter the collection name & check the validity
        my $name = $self->set('entry', '',
                              sub
                              {
                                  $self->validate_entry(shift, $window);
                              });

        $box->pack_start($self->set('frame', 'FrameCollectionName', $name),
                         0, 0, 0);

        # choose the collection type
        my $collection = $self->set_frame_list(
            'combo_box', $box, 'FrameCollectionType', 'Collection');

        # choose the website type
        my $websites = $self->set_frame_list(
            'check_buttons', $box, 'FrameCollectionWebsites', 'Web');

        # set collection color
        my $color = $self->set_frame_list(
            'button_drawing_area', $box, 'Color');

        # validate
        $box->pack_end(
            $self->set(
                'button', 'ButtonValidate',
                sub
                {
                    if (defined(
                            $self->classify->set_collection(
                                $self->validate_entry($name, $window) // return,
                                $self->validate_type($collection, $window) // return,
                                validate_check_buttons($websites))))
                    {
                        undef $window;
                        Gtk2->main_quit if defined $cb;
                    }
                }), 0, 0, 0);

        $box->show;

        $window->add($box);

        $window->show_all;
    }
}

=item $obj->set_frame_list(TYPE, BOX, FRAME_NAME, LIST_NAME)

Encapsulate a check_button list I<LIST_NAME> in a frame called I<FRAME_NAME>.

I<TYPE> could be :
 - check_buttons
 - combo_box

=cut
sub set_frame_list
{
    my($self, $type, $box, $frame_name, $list_name) = @_;

    my $check_box = Gtk2::VBox->new(0, 0);

    my $check_buttons = $self->set(
        $type, $check_box,
        $list_name ? keys %{Classify::get_list($list_name)} : undef);


    $box->pack_start($self->set('frame', $frame_name, $check_box), 0, 0, 0);

    return $check_buttons;
}

=item validate_entry(ENTRY, WINDOW)

Return new text if I<ENTRY> is a valid collection name.

=cut
sub validate_entry
{
    my($self, $entry, $window) = @_;

    my $name = ($entry // return)->get_text;

    my $error;
    if ($name eq '')
    {
        $error = 'WrongCollectionName';
    }
    elsif (defined $self->classify->get_collection($name))
    {
        $error = 'AlreadyExistCollectionName';
    }

    if (defined $error)
    {
        $self->set_error_message_dialog($window, $error);
        $entry->set_text('');
        return undef;
    }

    return $entry->get_text;
}

=item validate_type(COMBO_BOX, WINDOW)

=cut
sub validate_type
{
    my($self, $combo_box, $window) = @_;

    my $name = ($combo_box // return)->get_active_text;
    unless (defined $name)
    {
        $self->set_error_message_dialog(
            $window, 'WrongFrameCollectionType');
        return undef;
    }

    return $name;
}

=item validate_check_buttons(CHECK_BUTTON_LIST)

Return all validated check button lists

=cut
sub validate_check_buttons
{
    my $list = shift;
    my @validated;

    while(my($value, $check_button) = each %$list)
    {
        push(@validated, $value) if $check_button->get_active();
    }

    return @validated;
}

=item set_error_message_dialog(WINDOW, ERROR)

Display a warning window.

=cut
sub set_error_message_dialog
{
    my($self, $window, $error) = @_;

    my $dialog = $self->set(
        'message_dialog', $window, 'destroy-with-parent', 'error', 'none',
        $self->translate($error));

    $dialog->show_all;
}

=item $obj->collections_bar()

Permet d'afficher la barre des collections

=cut
sub collections_bar
{

}

1;
__END__

