package Classify::Collection::Cinema;
use parent Classify::Collection;

use strict;
use warnings;

use Moo;

use feature 'say';

use Data::Dumper;

has config_movies => (
    is => 'rw',
);

has config_subtitles => (
    is => 'rw',
);

has subtitles_not_linked => (
    is => 'rw',
);

=item info

Return collection description.

=cut
sub info
{
    return "handle, search & classify movies!\n"
        . "\taccepted configuration keys :\n"
        . "\t 'movies' = set movies extensions\n"
        . "\t 'subtitles' = set subtitles extensions";
}

=item $obj->input

We handle here all the files imported.

=cut
sub input
{
    my($self, $input) = @_;

    my($type, $extension, $url) = $input->get(qw(type extension url));

    return unless defined $type and $type eq 'file';

    # we filter subtitles
    if (defined $self->config_subtitles
        and $extension ~~ $self->config_subtitles)
    {
        $self->handle_subtitle($input);
        return;
    }

    # we filter movies file
    return if (defined $self->config_movies
               and not $extension ~~ $self->config_movies);

    $self->imported->{$url} = $input;

    say "add new movie :\n" . $input->info . "\n";

    # we check if some subtitles match the new movie;
    $self->check_movie_match_subtitles($input)
        if defined $self->subtitles_not_linked;
}

=item $obj->handle_subtitle

We handle subtitle and search for matching movies.

=cut
sub handle_subtitle
{
    my($self, $subtitle) = @_;

    # 1st : we search for similar movie name in the imported list
    unless ($self->check_subtitle_match_movies($subtitle))
    {
        if (not defined $self->subtitles_not_linked)
        {
            $self->subtitles_not_linked({});
        }

        $self->subtitles_not_linked->{$subtitle->url} = $subtitle;
    }
}

=item $obj->check_movie_match_subtitles(MOVIE)

=cut
sub check_movie_match_subtitles
{
    my($self, $movie) = @_;

    while (my(undef, $subtitle) = each(%{$self->subtitles_not_linked}))
    {
        $self->link_subtitle_to_movie($subtitle, $movie)
            if $subtitle->get('name') eq $movie->get('name');
    }
}

=item $obj->check_subtitle_match_movies(SUBTITLE)

=cut
sub check_subtitle_match_movies
{
    my($self, $subtitle) = @_;

    my $ret;

    while (my(undef, $movie) = each(%{$self->imported}))
    {
        if ($subtitle->get('name') eq $movie->get('name'))
        {
            $self->link_subtitle_to_movie($subtitle, $movie);
            $ret = 1;
        }
    }

    return $ret;
}

=item $obj->link_subtitle_to_movie(SUBTITLE, MOVIE)

Link subtitle with specified movie.

=cut
sub link_subtitle_to_movie
{
    my($self, $subtitle, $movie) = @_;

    # we delete subtitle from the list if it exists
    delete $self->subtitles_not_linked->{$subtitle->get('url')};

    # we link the subtitle with the movie
    $movie->set_after('subtitle', $subtitle);

    say "found new subtitle for movie " . $movie->get('name');
}

1;
__END__
