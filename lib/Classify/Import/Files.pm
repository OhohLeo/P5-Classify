package Classify::Import::Files;
use parent Classify::Import;

use strict;
use warnings;

use AnyEvent::AIO;
use IO::AIO;

use Moo;

use Classify::Object::File;
use Classify::Object::Directory;

use feature 'say';

has is_recursive => (
   is => 'rw',
 );

has display => (
   is => 'rw',
 );

has stop_now => (
   is => 'rw',
 );

=item info

=cut
sub info
{
    return ' [ path is_recursive ] - analyse directories or files.';
}

=item launch

=cut
sub launch
{
    my($self, $path) = @_;

    $self->stop_now(undef);

    $self->scan($path // $self->path);
}

=item stop

=cut
sub stop
{
    my $self = shift;

    $self->stop_now(1);

    $self->SUPER::stop();
}


=item scan

=cut
sub scan
{
    my($self, $path) = @_;

    return if defined $self->stop_now;

    aio_scandir(
        $path, 0,
        sub
        {
            my($dirs, $nondirs) = @_;

            return if defined $self->stop_now;

            if (defined $nondirs)
            {
                foreach my $name (@$nondirs)
                {
                    $self->output(Classify::Object::File->new(
                                  name => $name,
                                  url => $path));
                    $self->update_display($name);
                }
            }

            return unless defined $dirs;

            foreach my $name (@$dirs)
            {
                $self->output(Classify::Object::Directory->new(
                                  name => $name,
                                  url => $path));
                $self->update_display($name);
                $self->scan("$path/$name") if defined $self->is_recursive;
            }
        });
}

=item update_display

=cut
sub update_display
{
    (shift->display // return)->update(shift, 0);
}

1;
__END__
