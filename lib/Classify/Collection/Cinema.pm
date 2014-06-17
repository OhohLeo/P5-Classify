package Classify::Collection::Cinema;
use parent Classify::Collection;

use Moo;

use Classify::Research;

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

# researches are totally generic to the collection
our %RESEARCHES = (
    'movie' => Classify::Research::->new(
	name => 'movie',
	data_types => {
	}),
    'subtitle' => Classify::Research::->new(
	name => 'subtitle',
	data_types => {
	})
    );

=head2 METHODS

=over 4

=item BUILD

=cut
sub BUILD
{
    shift->researches(\%RESEARCHES);
}

=item info()

Return collection description.

=cut
sub info
{
    return "Handle, Search & Classify Movies!\n"
        . "\t configuration keys =\n"
        . "\t  'movies' = set movies extensions\n"
        . "\t  'subtitles' = set subtitles extensions";
}

=item $obj->create_movie()

=cut

=item $obj->create_subtitle()

=cut

=item $obj->input(INPUT)

We handle here all the files imported.

=cut
sub input
{
    my($self, $input) = @_;

    my($type, $extension, $url) = $input->get(qw(type extension url));

    return unless defined $type and $type eq 'file';

    # we filter file that already exists
    if (exists $self->imported->{$url})
    {
        $self->log_warn("'$url' already exists in collection " . $self->name);
        #return;
    }

    # we filter subtitles
    if (defined $self->config_subtitles
        and $extension ~~ $self->config_subtitles)
    {
        $self->subtitle_handle($input);
        return;
    }

    # we filter movies file
    return if (defined $self->config_movies
               and not $extension ~~ $self->config_movies);

    # we check if some subtitles match the new movie
    $self->subtitles_match_movie($input)
        if $self->subtitles_not_linked;

    # we check if the movie can be linked with other movies
    # $self->movie_match_other_movies($input);

    # we store the new movie;
    $self->imported->{$url} = $input;

    $self->info("\nadd new movie :\n" . $input->info . "\n");

    # we launch web classify process
    $self->web_search($input) if defined $self->websites;
}

=item $obj->subtitle_handle(SUBTITLE)

We handle subtitle and search for matching movies.

=cut
sub subtitle_handle
{
    my($self, $subtitle) = @_;

    # 1st : we search for similar movie name in the imported list
    unless ($self->subtitle_match_movies($subtitle))
    {
        $self->subtitles_not_linked({})
            unless defined $self->subtitles_not_linked;

        $self->subtitles_not_linked->{$subtitle->get('url')} = $subtitle;
    }
}

=item $obj->subtitle_match_movies(SUBTITLE)

=cut
sub subtitle_match_movies
{
    my($self, $subtitle) = @_;

    my $ret;

    while (my(undef, $movie) = each(%{$self->imported}))
    {
        if ($subtitle->get('name') eq $movie->get('name'))
        {
            $self->subtitle_link_to_movie($subtitle, $movie);
            $ret = 1;
        }
    }

    return $ret;
}

=item $obj->subtitles_match_movie(MOVIE)

=cut
sub subtitles_match_movie
{
    my($self, $movie) = @_;

    while (my(undef, $subtitle) = each(%{$self->subtitles_not_linked}))
    {
        $self->subtitle_link_to_movie($subtitle, $movie)
            if $subtitle->get('name') eq $movie->get('name');

        # XXX We can't make probability stuff here!!
    }
}

=item $obj->subtitle_link_to_movie(SUBTITLE, MOVIE)

Link subtitle with specified movie.

=cut
sub subtitle_link_to_movie
{
    my($self, $subtitle, $movie) = @_;

    # we delete subtitle from the list if it exists
    if ($self->subtitles_not_linked)
    {
        delete $self->subtitles_not_linked->{$subtitle->get('url')};

        $self->subtitles_not_linked(undef)
            unless %{$self->subtitles_not_linked};
    }

    # we link the subtitle with the movie
    $movie->set_after('subtitle', $subtitle);

    $self->log_great("found new subtitle for movie " . $movie->get('name'));
}


=item $obj->movie_match_other_movies(NEW_MOVIE)

=cut
sub movie_match_other_movies
{
    my($self, $new_movie) = @_;

    while (my(undef, $movie) = each(%{$self->imported}))
    {
        if ($new_movie->get('name') eq $movie->get('name'))
        {
            # we link the new movie with the movie
            $new_movie->set_after('other_movies', $movie);
            $movie->set_after('other_movies', $new_movie);

            $self->log_great("found links between two movies " . $movie->get('name'));
        }
    }
}

1;
__END__
