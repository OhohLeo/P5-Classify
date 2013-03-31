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

Permet de créer un menu en fonction de paramètres.

=cut
sub set
{
    my($self, $method_name) = splice(@_, 0, 2);

    if (defined(my $method = $self->can("set_$method_name")))
    {
        return $method->($self->translate(@_));
    }
}

=item $obj->translate(SHEET_NAME, DATA ...)

Return I<DATA> translate.

=cut
sub translate
{
    return shift->classify->translate(@_);
}

=item set_submenu(SET, MENU, NAME, DATA)

Permet de créer un sous-menu en fonction de paramètres.

I<NAME> est le nom du menu et le suivant est une référence vers un tableau
contenant le nom du sous-menu et son callback à appeler.

=cut
sub set_submenu
{
    my($set, $menu, $name, $data) = @_;

    my $submenu = Gtk2::MenuItem->new_with_label($name);
    $submenu->set_submenu($menu) if defined $set;

    for (ref $data)
    {
        when ('ARRAY')
        {
            while (@$data)
            {
                my($item_name, $cb) = splice(@$data, 0, 2);
                my $menu_item = Gtk2::MenuItem->new_with_label($item_name);
                $menu_item->signal_connect('button_press_event' => $cb);
                $menu->append($menu_item);
            }
        }

        when ('CODE')
        {
            $data->($submenu);
        }
    }

    return $submenu;
}

=item set_menu(NAME, DATA, [ NAME, DATA ] ...)

Permet de créer un menu en fonction de paramètres.

I<NAME> est le nom du menu et le suivant est une référence vers un tableau
contenant le nom du sous-menu et son callback à appeler.

=cut
sub set_menu
{
    my $menu = Gtk2::Menu->new();

    while (@_)
    {
        $menu->append(set_submenu(undef, $menu, splice(@_, 0, 2)));
    }

    return $menu;
}


=item set_menu_bar(NAME, DATA, [ NAME, DATA ] ...)

Permet de créer une barre des menu en fonction de paramètres.

I<NAME> est le nom du menu et le suivant est une référence vers un tableau
contenant le nom du sous-menu et son callback à appeler.

=cut
sub set_menu_bar
{

    my $menu_bar = Gtk2::MenuBar->new();

    while (@_)
    {
        my $menu = Gtk2::Menu->new();
        $menu_bar->append(set_submenu(1, $menu, splice(@_, 0, 2)));
    }

    return $menu_bar;
}

=item set_progress_bar(NAME, BOX_TO_PUT_INSIDE)

Permet de créer un cadre pouvant contenir une box.

I<NAME> est le nom du cadre.

=cut
sub set_progress_bar
{
    my $progress_bar = Gtk2::ProgressBar->new();

    $progress_bar->set_text('progress bar');
    $progress_bar->show;

    return $progress_bar;
}

=item set_window(NAME, BORDER_WIDTH, DESTROY_CB)

Create new window called I<NAME>.

Call I<DESTROY_CB> when the window is closed.

=cut
sub set_window
{
    my $window = Gtk2::Window->new;

    $window->set_title(shift);
    $window->set_border_width(shift // 0);
    $window->signal_connect(destroy => shift // sub {});

    return $window;
}

=item set_frame(NAME, BOX, TYPE, X, Y)

Create a frame with I<NAME> as name and I<X>, I<Y> for the alignement.

I<TYPE> value could be :
    - 'none'
    - 'in'
    - 'out'
    - 'etched_in' (by default)
    - 'etched_out'

=cut
sub set_frame
{
    my $frame = Gtk2::Frame->new(shift);

    $frame->add(shift);
    $frame->set_shadow_type(shift // 'etched_in');
    $frame->set_label_align(@_) if @_;

    return $frame;
}

=item set_label(TEXT, [ SIZE, COLOR, JUSTIFY, WRAP ])

Create a text label with I<TEXT>.

I<COLOR> could be :
    - yellow
    - green
    - blue

I<JUSTIFY> value could be :
    - 'left'
    - 'right'
    - 'center' (default)
    - 'fill'

I<WRAP> could be 1 or 0.

=cut
sub set_label
{
    my($text, $size, $color, $justify, $wrap) = @_;
    my $label = Gtk2::Label->new($text);

    $label->set_markup("<span foreground=\"$color\" size=\"$size\">$text</span>")
        if defined $size and defined $color;
    $label->set_justify($justify) if defined $justify;
    $label->set_line_wrap($wrap) if defined $wrap;

    return $label;
}

=item set_entry(TEXT, CB)

Create an input text with I<NAME> as frame name and I<TEXT> as inside text.

I<CB> is called when we press enter.

=cut
sub set_entry
{
    my $entry = Gtk2::Entry->new();

    $entry->set_text(shift);

    $entry->signal_connect(activate => shift // sub {});

    return $entry;
}

=item set_button(NAME, CB)

Create a button with I<NAME> displayed inside.

I<CB> is called when we click on the button.

=cut
sub set_button
{
    my $button = Gtk2::Button->new(shift);

    $button->signal_connect(clicked => shift // sub {});

    return $button;
}

=item set_combo_box(BOX, LIST)

=cut
sub set_combo_box
{
    my $box = shift;

    my $combo_box = Gtk2::ComboBox->new_text;

    $combo_box->set_focus_on_click(1);

    foreach (@_)
    {
        $combo_box->append_text($_);
    }

    $box->pack_start($combo_box, 0, 0, 0);

    return $combo_box;
}

=item set_check_buttons(BOX, LIST)

=cut
sub set_check_buttons
{
    my $box = shift;

    my %check_buttons;

    foreach (@_)
    {
        my $check_button = Gtk2::CheckButton->new($_);
        $check_buttons{$_} = $check_button;
        $box->pack_start($check_button, 0, 0, 0);
    }

    return \%check_buttons;
}

=item set_message_dialog(PARENT, FLAGS, TYPE, BUTTONS, MESSAGE, CB)

Create a button with I<NAME> displayed inside.

I<CB> is called when we click on the button.

I<FLAGS> could be :
 - 'modal'
 - 'destroy-with-parent'
 - 'no-separator'

I<TYPE> could be :
 - 'info'
 - 'question'
 - 'error'
 - 'warning'

I<BUTTON> could be :
 - 'none'
 - 'ok'
 - 'close'
 - 'cancel'
 - 'yes-no'
 - 'ok-cancel'

=cut
sub set_message_dialog
{
    return Gtk2::MessageDialog->new(@_);
}

=item set_button_drawing_area(BOX)

=cut
sub set_button_drawing_area
{
    my $box = shift;

    my $button = Gtk2::Button->new();
    $button->show();
    $box->pack_start( $button, 0, 0, 0 );

    # Create a button box
    my $buttonbox = new Gtk2::VBox(0, 0);
    $buttonbox->show();
    $button->add($buttonbox);

    # Create the drawing area used to display the color
    my $drawingarea = new Gtk2::DrawingArea();
    $drawingarea->size(32, 32);
    $drawingarea->show();
    $buttonbox->pack_start($drawingarea, 0, 0, 0);

    # Create a random color
    my $color = Gtk2::Gdk::Color->new(
        rand(0xffff), rand(0xffff), rand(0xffff));

    $drawingarea->modify_bg('normal', $color);

    my $color_selection;

    $button->signal_connect(
        'clicked',
        sub
        {
            return if defined $color_selection;

            # Create color selection dialog
            $color_selection = new Gtk2::ColorSelectionDialog('');

            $color_selection->signal_connect(
                'response', sub
                {
                    $color_selection->hide();
                    undef $color_selection;
                });

            # Connect to the 'color_changed' signal, set the client-data
            # to the colorsel widget
            $color_selection->colorsel->signal_connect(
                'color_changed', sub
                {
                    $color = shift->get_current_color();
                    $drawingarea->modify_bg('normal', $color);
                });

            # Show the dialog
            $color_selection->show();

        });

    return $color;
}



1;

