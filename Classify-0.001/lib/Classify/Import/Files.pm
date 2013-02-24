package Classify::Import::Files;
use parent Classify::Import;

use strict;
use warnings;

use AnyEvent::AIO;
use IO::AIO;

use Moo;

use Classify::Model;

use feature qw(say state);

has is_recursive => (
   is => 'rw',
 );

has nb_of_files => (
   is => 'rw',
 );

has condvar => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item info

=cut
sub info
{
    return '{ path is_recursive } - analyse directories or files.';
}

=item launch

=cut
sub launch
{
    my($self, $path) = @_;

    # anyevent condvar initialisation
    $self->condvar(AnyEvent->condvar);

    $path //= $self->path;

    # we start the display
    if (defined(my $display = $self->display))
    {
        $self->nb_of_files(1);

        $display->start;

        $self->update_display("Wait for analyse...", 0);

        my $ref_count;
        $$ref_count = 0;
        $self->scan_count($path, $ref_count);

        $self->con_dvar->recv;

        $self->nb_of_files($$ref_count);
    }

    $self->scan($path);
}

=item scan_count

=cut
sub scan_count
{
    my($self, $path, $ref_count) = @_;

    state $count_directories = 0;

    aio_scandir(
        $path, 0,
        sub
        {
            my($dirs, $nondirs) = @_;

            $count_directories-- if $count_directories > 0;

            $$ref_count += @$nondirs // 0 if defined $nondirs;

            if (defined $dirs)
            {
                $$ref_count += @$dirs // 0;
                $count_directories += @$dirs;

                foreach my $name (@$dirs)
                {
                    $self->scan_count("$path/$name", $ref_count)
                        if defined $self->is_recursive;
                }
            }

            $self->condvar->send
                if $count_directories == 0 or not $self->is_recursive;
        });
}

=item scan

=cut
sub scan
{
    my($self, $path) = @_;

    state $count_files = 0;
    state $count_directories = 0;

    aio_scandir(
        $path, 0,
        sub
        {
            my($dirs, $nondirs) = @_;

            $count_directories-- if $count_directories > 0;

            foreach my $name (@$nondirs)
            {
                if ($name =~ $self->filter)
                {
                    my $orig_name = $name;
                    my $extension;
                    if ($name =~ s/\.(.*)$//)
                    {
                        $extension = $1;
                    }

                    $self->output(
                        Classify::Model::->new(
                            type => 'file',
                            name => $name,
                            path => $path,
                            extension => $extension,
                            url => "$path/$orig_name"));
                }

                $self->update_display($name, $count_files)
                    unless defined $self->is_recursive;

                $count_files++;
            }

            foreach my $name (@$dirs)
            {
                if ($name =~ $self->filter)
                {
                    $self->output(
                        Classify::Model::->new(
                            type => 'directory',
                            name => $name,
                            url => $path,
                        ));
                }

                $self->update_display($name, $count_files);

                $self->scan("$path/$name") if defined $self->is_recursive;
            }

            $count_directories += @$dirs;

            $self->condvar->send
                if $count_directories == 0 or not $self->is_recursive;
        });
}

=item update_display

=cut
sub update_display
{
    my($self, $name, $count) = @_;

    ($self->display // return)->update($name, $count / $self->nb_of_files);
}


1;
__END__
