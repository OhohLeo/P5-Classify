package Classify::Display::Classify;
use parent Classify;

use Classify::Display;
use Classify::Display::Collections;

use Moo;

use Gtk2 '-init';

has window => (
   is => 'rw',
 );

has on_stop => (
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

    $self->on_stop(sub { $self->stop; });
}

=item $obj->init()

Permet d'initialiser l'affichage.

=cut
sub init
{
    my $self = shift;

    my $box = Gtk2::VBox->new(0, 0);

    # init menu bar
    $box->pack_start($self->display_menu_bar, 0 , 0, 0);

    # # init collections bar
    $box->pack_start($self->collections->display_menu_collections, 0, 0, 0);

    # init log bar

    $box->show;

    return $box;
}

=item $obj->start

=cut
sub start
{
    my $self = shift;

    $self->log_great("Classify is starting up.");

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

    $self->SUPER::stop;
}

=item $obj->refresh()

Refresh all current display.

=cut
sub refresh
{
    shift->window->show_all;
}

=item $obj->set_collections()

Classify constructor call this method.

=cut
sub set_collections
{
    my $self = shift;

    # collections display initialisation
    $self->collections(Classify::Display::Collections::->new(
			   classify => $self));
}

=item $obj->set(METHOD_NAME, PATH, NAME, DATA, [ NAME, DATA ] ...)

Permet de créer un menu en fonction de paramètres.

=cut
sub set
{
    my($self, $method_name) = splice(@_, 0, 2);

    if (defined(my $method = $self->can("Classify::Display::set_$method_name")))
    {
        return $method->($self->translate('Classify', @_));
    }
}

=item $obj->display_menu_bar()

Display bar menu.

=cut
sub display_menu_bar
{
    my $self = shift;

    return $self->set(
        'menu_bar',
        'MenuFile', [ 'MenuNewCollection',
		      $self->collections->menu_new_collection,
                      'MenuImport', sub {},
                      'MenuExport', sub {},
                      'MenuLeave', sub { $self->stop; }],
        'MenuConfiguration', []),
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

    $self->log_warn($error);

    my $dialog = $self->set(
        'message_dialog', $window, 'destroy-with-parent',
        'error', 'none', $error);

    $dialog->show_all;
}


1;
__END__
