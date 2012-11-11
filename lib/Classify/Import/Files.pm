package Classify::Import::Files;
use parent Classify::Import;

use strict;
use warnings;

use AnyEvent::IO;
use Moo;

use feature 'say';

has path => (
   is => 'rw',
 );

has is_recursive => (
   is => 'rw',
 );

has display => (
   is => 'rw',
 );

has file_current => (
   is => 'rw',
 );

has file_nb => (
   is => 'rw',
 );

has stop_now => (
   is => 'rw',
 );

sub launch
{
    my($self, $path) = @_;

    if (defined $self->display)
    {

    }

    $self->stop_now(undef);
    $self->analyse($path);
}

sub analyse
{
    my($self, $path) = @_;

    return if $self->stop_now;

    $path //= $self->path;
    my $nb = 0;

    aio_readdir(
        $path,
        sub
        {
            my $names = shift or return;

            return if $self->stop_now;

            foreach my $name (@$names)
            {
                return if $self->stop_now;

                aio_lstat(
                    "$path/$name",
                    sub
                    {
                        return if $self->stop_now;

                        print "$path/$name\n";
                        if (-f _)
                        {
                            $self->feed_collections($path, $name);
                            $self->file_current("$path/$name");
                            $self->file_nb(++$nb);
                        }

                        $self->launch("$path/$name")
                            if (-d _ and $self->is_recursive);
                    });
            }
        });
}

sub stop
{
    warn "HERE STOP!";
    shift->stop_now(1);
}

1;
__END__
