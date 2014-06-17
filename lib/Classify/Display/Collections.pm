package Classify::Display::Collections;
use parent Classify::Collections;

use strict;
use warnings;

use Classify::Display::Collection;

use Moo;

has notebook => (
   is => 'rw',
 );

has displayed_collections => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item BUILD

Retreive collections if they exist & initialize display if needed.

=cut
sub BUILD
{
    my $self = shift;

    # displayed collections initialisation
    $self->displayed_collections({});
}

=item $obj->display_menu_collections()

Display new collection menu.

=cut
sub display_menu_collections
{
    my $self = shift;

    my $notebook = Gtk2::Notebook->new;
    $notebook->set_scrollable(1);
    $notebook->popup_disable;
    $notebook->set_tab_hborder(0);

    my @collections = values $self->collections;

    my $position = 0;
    foreach my $collection (@collections)
    {
        $self->add_collection_to_display($collection, $notebook);
    }

    # display add collection button
    my $tab = Gtk2::Button->new('+');
    $tab->set_relief('none');
    $tab->signal_connect('clicked', $self->menu_new_collection);
    $notebook->append_page(Gtk2::VBox->new(0,0), $tab);

    $self->notebook($notebook);

    return $notebook;
}

=item $obj->add_collection_to_display(COLLECTION, NOTEBOOK)

Add new collection in the collections menu.

=cut
sub add_collection_to_display
{
    my($self, $collection, $notebook) = @_;

    # create the collection to display
    my $displayed_collection = Classify::Display::Collection::->new(
	collection => $collection);

    my($name, $color) = ($collection->name,
			 $displayed_collection->color);

    $notebook //= $self->notebook // return;

    # $color = Gtk2::Gdk::Color->new(@$color);

    # display tab
    my $tab = Gtk2::Button->new($name);
    $tab->set_relief('none');
    #$tab->modify_bg('selected', $color);

    # display collection content
    my $child = Gtk2::VBox->new(0,0);

    # get position id
    my $id = $notebook->insert_page($child, $tab, 0);

    # store position id on displayed collection object
    $displayed_collection->position($id);

    # store displayed_collections object
    $self->displayed_collections->{$name} = $displayed_collection;

    # refresh collection;
    $self->refresh_add_collection($name);

    # destroy collection
    $tab->signal_connect(
        'button_press_event',
        sub
        {
            my(undef, $event) = @_;

            # click gauche : on affiche un sous menu
            if ($event->button == 3)
            {
                my $menu = $self->classify->set(
                    'menu',
                    'PopupCollectionMenuConfig',
                    $self->menu_config_collection($displayed_collection),
                    'PopupCollectionMenuDelete',
                    $self->menu_delete_collection(
                        $name, $notebook,
                        $displayed_collection->position));

                $menu->popup(undef, undef, undef, undef,
                             $event->button,
                             $event->time);

                $menu->show_all;

                return;
            }

            $notebook->set_current_page($displayed_collection->position);
        });


    $notebook->show_all;
}

=item $obj->refresh_add_collection(EXCEPTION)

Increment all collections with 1 expect the collection called I<EXCEPTION>.

=cut
sub refresh_add_collection
{
    my($self, $new_name) = @_;

    while (my($name, $collection) = each %{$self->displayed_collections})
    {
        next if $name eq $new_name;

        $collection->position($collection->position + 1);
    }
}

=item $obj->refresh_delete_collection(POSITION)

Decrement all collections with 1 from I<POSITION>.

=cut
sub refresh_delete_collection
{
    my($self, $from) = @_;

    while (my(undef, $collection) = each %{$self->displayed_collections})
    {
        next unless $collection->position > $from;

        $collection->position($collection->position - 1);
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

        my $window = $self->classify->set(
	    'window', 'MenuNewCollection', 10, $cb);

        my $box = Gtk2::VBox->new(1, 2);

        # enter the collection name & check the validity
        my $name = $self->classify->set(
	    'entry', '',
	    sub
	    {
		$self->validate_entry(shift, $window);
	    });

        $box->pack_start($self->classify->set(
			     'frame', 'FrameCollectionName', $name),
                         0, 0, 0);

        # choose the collection type
        my $collection = $self->classify->set_frame_list(
            'combo_box', $box, 'FrameCollectionType', 'Collection');

        # choose the website type
        my $websites = $self->classify->set_frame_list(
            'check_buttons', $box, 'FrameCollectionWebsites', 'Web');

        # set collection color
        my $color = $self->classify->set_frame_list(
            'button_drawing_area', $box, 'Color');

        # validate
        $box->pack_end(
            $self->classify->set(
                'button', 'ButtonValidate',
                sub
                {
                    my $collection = $self->add(
                        $self->validate_entry($name, $window) // return,
                        $self->validate_type($collection, $window) // return,
                        Classify::Display::Classify::validate_check_buttons(
			    $websites));

                    if (defined $collection)
                    {
                        $collection->set_color($color);
                        $self->add_collection_to_display($collection);
                        $window->destroy;

                        Gtk2->main_quit if defined $cb;
                    }
                }), 0, 0, 0);

        $box->show;

        $window->add($box);

        $window->show_all;

        $self->classify->refresh;
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

        # we display a confirm menu
        shift->signal_connect(
            'button_press_event' => sub
            {
                $self->classify->set_confirm_message_dialog(
                    $self->classify->window,
                    'PopupCollectionMenuConfirmDelete',
                    sub {
                        if (shift eq 'yes')
                        {
                            my $collection =
                                $self->delete($name);

                            $self->refresh_delete_collection(
				$collection->position);

                            $notebook->remove_page($id);
			}
                    });
            });
    }
}

=item $obj->menu_config_collection()

#XXX TO FINISH!

Display config collection menu.

=cut
sub menu_config_collection
{
    my($self, $collection) = @_;

    return sub
    {
        $self // return;

        shift->signal_connect(
            'button_press_event' => sub
            {
                my $window = $self->classify->set(
		    'window', 'MenuConfiguration', 10);

                my $box = Gtk2::VBox->new(1, 2);

                # rename the collection & check the validity
                my $name = $self->classify->set(
		    'entry', '',
		    sub
		    {
			$self->validate_entry(shift, $window);
		    });

                $box->pack_start($self->classify->set(
				     'frame', 'FrameCollectionRename',
				     $name),
                                 0, 0, 0);

                # choose the website type
                my $websites = $self->classify->set_frame_list(
                    'check_buttons', $box, 'FrameCollectionWebsites', 'Web');

                # set collection color
                my $color = $self->classify->set_frame_list(
                    'button_drawing_area', $box, 'Color');

                # ajouter la gestion des attributs de type config_*
                # éventuellement présent dans la collection!

                # validate
                $box->pack_end(
                    $self->classify->set(
                        'button', 'ButtonValidate',
                        sub
                        {
                            $collection->name(
                                $self->validate_entry($name, $window)
                                // return);


                            Classify::Display::Classify::validate_check_buttons(
				$websites);

                            if (defined $collection)
                            {
                                $collection->set_color($color);
                                $window->destroy;

                            }
                        }), 0, 0, 0);

                $box->show;

                $window->add($box);

                $window->show_all;

                $self->classify->refresh;
            });
    }
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
    elsif (defined $self->get($name))
    {
        $error = 'AlreadyExistCollectionName';
    }

    if (defined $error)
    {
        $self->classify->set_error_message_dialog($window, $error);
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
        $self->classify->set_error_message_dialog(
            $window, 'WrongFrameCollectionType');
        return undef;
    }

    return $name;
}

1;
__END__
