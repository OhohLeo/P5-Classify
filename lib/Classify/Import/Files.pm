package Classify::Import::Files;
use parent Classify::Import;

use strict;
use warnings;

use AnyEvent::IO;
use Moo;

use feature 'say';

has is_recursive => (
   is => 'rw',
 );

has file_current => (
   is => 'rw',
 );

has file_nb => (
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

    if (defined $self->display)
    {
    }

    $self->stop_now(undef);
    $self->analyse($path);
}

=item analyse

=cut
sub analyse
{
    my($self, $path) = @_;

    return if defined $self->stop_now;

    $path //= $self->path;
    my $nb = 0;

    aio_readdir(
        $path,
        sub
        {
            my $names = shift or return;

            return if defined $self->stop_now;

            foreach my $name (@$names)
            {
                return if $self->stop_now;

                aio_lstat(
                    "$path/$name",
                    sub
                    {
                        return if defined $self->stop_now;

                        $self->output(
                            {
                                path => $path,
                                name => $name
                            });
                        # $self->file_current("$path$name");
                        # $self->file_nb(++$nb);

                        $self->analyse("$path/$name")
                            if (-d _ and defined $self->is_recursive);
                    });
            }
        });
}

1;
__END__
