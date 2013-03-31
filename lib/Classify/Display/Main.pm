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

has notebook => (
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

    $window->resize(300, 400);

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

    # init menu bar
    $box->pack_start($self->menu_bar, 0 , 0, 0);

    # init collections bar
    $box->pack_start($self->menu_collections, 0, 0, 0);

    # init log bar

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

=item $obj->refresh()

Refresh all current display.

=cut
sub refresh
{
    shift->window->show_all;
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

=item $obj->menu_collections()

Display new collection menu.

=cut
sub menu_collections
{
    my $self = shift;

    my $notebook = Gtk2::Notebook->new;
    $notebook->set_scrollable(1);
    $notebook->popup_disable;
    $notebook->set_tab_hborder(0);

    my @collections = values $self->classify->collections;

    foreach my $collection (@collections)
    {
        $collection->position(0);
        $self->add_collection($collection, $notebook);
    }

    # display add collection button
    my $tab = Gtk2::Button->new('+');
    $tab->set_relief('none');
    $tab->signal_connect('clicked', $self->menu_new_collection);
    $notebook->append_page(Gtk2::VBox->new(0,0), $tab);

    $self->notebook($notebook);

    return $notebook;
}

=item $obj->add_collection(COLLECTION, NOTEBOOK)

Add new collection in the collections menu.

=cut
sub add_collection
{
    my($self, $collection, $notebook) = @_;

    $notebook //= $self->notebook // return;

    my($name, $color) = ($collection->name, $collection->color);

    #$color = Gtk2::Gdk::Color->new(@$color);

    # display tab
    my $tab = Gtk2::Button->new($name);
    $tab->set_relief('none');
    #$tab->modify_bg('selected', $color);

    # display collection content
    my $child = Gtk2::VBox->new(0,0);

    my $id = $notebook->insert_page($child, $tab, 0);

    # destroy collection
    $tab->signal_connect(
        'button_press_event',
        sub
        {
            my(undef, $event) = @_;

            # click gauche : on affiche un sous menu
            if ($event->button == 3)
            {
                my $menu = $self->set(
                    'menu',
                    'PopupCollectionMenuConfig',
                    sub {},
                    'PopupCollectionMenuDelete',
                    $self->menu_delete_collection(
                        $name, $notebook,
                        $collection->position));

                $menu->popup(undef, undef, undef, undef,
                             $event->button,
                             $event->time);

                $menu->show_all;

                return;
            }

            $notebook->set_current_page($id);
        });


    $notebook->show_all;
}

=item $obj->refresh_collections(TYPE, POSITION)

Refresh collections ids.

If I<TYPE> == 0 : increment all collections with 1.

If I<TYPE> > 0  : decrement all collections with 1 from I<POSITION>.

=cut
sub refresh_collections
{
    my($self, $type, $from) = @_;

    my @collections = values $self->classify->collections;

    foreach my $collection (@collections)
    {
        my $position = $collection->position();

        if ($type == 0)
        {
            $position++;
        }
        elsif ($type > 0 and $position > $from)
        {
            $position--;
        }

        warn $collection->name . " $position ";

        $collection->position($position);
    }
}

=item $obj->menu_new_collection()

Display new collection menu.

=cut
sub menu_new_collection
{
    my $self = shift;

    return sub
    {
        $self // return;

        my $cb = shift;

        undef $cb unless ref $cb eq 'CODE';

        my $window = $self->set('window', 'MenuNewCollection', 10, $cb);

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
                    $self->refresh_collections(0);

                    my $collection = $self->classify->set_collection(
                        $self->validate_entry($name, $window) // return,
                        $self->validate_type($collection, $window) // return,
                        validate_check_buttons($websites));

                    if (defined $collection)
                    {
                        $collection->set_color($color);
                        $self->add_collection($collection);
                        $window->destroy;

                        Gtk2->main_quit if defined $cb;
                    }
                }), 0, 0, 0);

        $box->show;

        $window->add($box);

        $window->show_all;

        $self->refresh;
    }
}

=item $obj->menu_delete_collection(NAME, NOTEBOOK, ID)

Display delete collection menu.

=cut
sub menu_delete_collection
{
    my($self, $name, $notebook, $id) = @_;

    return sub
    {
        $self // return;

        warn $name;

        # we display a confirm menu
        shift->signal_connect(
            'button_press_event' => sub
            {
                $self->set_confirm_message_dialog(
                    $self->window,
                    'PopupCollectionMenuConfirmDelete',
                    sub {
                        if (shift eq 'yes')
                        {
                            my $collection =
                                $self->classify->delete_collection($name);
                            $self->refresh_collections(1, $collection->position);
                            $notebook->remove_page($id);
                        }
                    });
            });
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
    if ($name eq '' or $name eq 'all')
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

=item set_confirm_message_dialog(WINDOW, MESSAGE, CB)

Display a warning window.

=cut
sub set_confirm_message_dialog
{
    my($self, $window, $message, $cb) = @_;

    $message = $self->translate($message);

    my $dialog = $self->set(
        'message_dialog', $window, 'destroy-with-parent',
        'question', 'yes-no', $message);

    $dialog->show_all;

    $cb->($dialog->run);
    $dialog->destroy;
}

=item set_error_message_dialog(WINDOW, ERROR)

Display a warning window.

=cut
sub set_error_message_dialog
{
    my($self, $window, $error) = @_;

    $error = $self->translate($error);

    $self->log_warn($error);

    my $dialog = $self->set(
        'message_dialog', $window, 'destroy-with-parent',
        'error', 'none', $error);

    $dialog->show_all;
}

1;
__END__

