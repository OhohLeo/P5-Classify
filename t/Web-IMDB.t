use Test::More;
plan tests => 19;

use Classify;
use Classify::Web::IMDB;

use Data::Dumper;

my $classify = Classify->new();

my $condvar = AnyEvent->condvar;

my $imdb = Classify::Web::IMDB::->new(classify => $classify);

my $requests_count = 1;

$imdb->req('Matrix', \&check_search);

sub check_search
{
    my $result = shift;

    is(exists($result->{character}), 1);
    is(exists($result->{star}), 1);
    is(exists($result->{movie}), 1);

    my $first_character = $result->{character}[0];

    is(ref $first_character,  Classify::Research);
    is($first_character->get('name'), 'Matrix');

    my $first_star = $result->{star}[0];

    is(ref $first_star,  Classify::Research);
    is($first_star->get('name'), 'Eddie Mariano');

    my $first_movie = $result->{movie}[0];

    is(ref $first_movie,  Classify::Research);
    is($first_movie->get('name'), 'Matrix');
    is($first_movie->get('year'), 1999);
    is($first_movie->get('seen_on'), undef);

    $condvar->send unless $requests_count--;
}

$imdb->req('http://www.imdb.com/title/tt0133093/', \&check_movie);

sub check_movie
{
    my $result = shift;

    is(ref $result, Classify::Research);
    # is($result->get('date'), "23 June 1999");
    is($result->get('original_name'), "The Matrix");
    # is($result->get('name'), "Matrix");
    is($result->get('duration'), "136 min");
    is($result->get('description'), "A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers.");
    is($result->get('budget'), "\$63,000,000");
    is($result->get('year'), "1999");
    is($result->get('poster'), "http://ia.media-imdb.com/images/M/MV5BMjEzNjg1NTg2NV5BMl5BanBnXkFtZTYwNjY3MzQ5._V1_SY317_CR6,0,214,317_.jpg");
    is_deeply($result->get('country'), [ 'USA', 'Australia' ]);
    # is_deeply($result->get('genre'), [ 'Action', 'Adventure', 'Sci-Fi' ]); XXX

    # is_deeply($result->get('directors'),
    #           [
    #             Classify::Research->new(
    #                 type => 'star',
    #                 url => 'http://www.imdb.com/name/nm0905152/',
    #                 name => 'Andy Wachowski'),
    #             Classify::Research->new(
    #                 type => 'star',
    #                 url => 'http://www.imdb.com/name/nm0905154/',
    #                 name => 'Lana Wachowski'),
    #           ]);

    # is_deeply($result->get('stars'),
    #           [
    #            Classify::Research->new(
    #                 type => 'star',
    #                 url => 'http://www.imdb.com/name/nm0000206/',
    #                 name => 'Keanu Reeves'),
    #             Classify::Research->new(
    #                 type => 'star',
    #                 url => 'http://www.imdb.com/name/nm0000401/',
    #                 name => 'Laurence Fishburne'),
    #             Classify::Research->new(
    #                 type => 'star',
    #                 url => 'http://www.imdb.com/name/nm0005251/',
    #                 name => 'Carrie-Anne Moss'),
    #           ]);

    $condvar->send unless $requests_count--;
}


$condvar->recv;
