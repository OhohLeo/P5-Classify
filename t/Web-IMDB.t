use Test::More;
plan tests => 24;

use Classify::Web::IMDB;

use Data::Dumper;

my $condvar = AnyEvent->condvar;

my $imdb = Classify::Web::IMDB::->new;

my $requests_count = 1;

$imdb->req('Matrix', \&check_search);
sub check_search
{
    my $result = shift;

    is(exists($result->{character}), 1);
    is(exists($result->{star}), 1);
    is(exists($result->{movie}), 1);

    my $first_character = $result->{character}[0];

    is(ref $first_character,  Classify::Object::Character);
    is($first_character->name, 'Matrix');

    my $first_star = $result->{star}[0];

    is(ref $first_star,  Classify::Object::Star);
    is($first_star->name, 'Eddie Mariano');

    my $first_movie = $result->{movie}[0];

    is(ref $first_movie,  Classify::Object::Movie);
    is($first_movie->name, 'Matrix');
    is($first_movie->year, 1999);
    is($first_movie->seen_on, undef);

    $condvar->send unless $requests_count--;
}

$imdb->req('http://www.imdb.com/title/tt0133093/', \&check_movie);
sub check_movie
{
    my $result = shift;

    is(ref $result, Classify::Object::Movie);
    is($result->date, "23 June 1999");
    is($result->original_name, "The Matrix");
    is($result->name, "Matrix");
    is($result->duration, "136 min");
    is($result->description, "A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers.");
    is($result->budget, "\$63,000,000 (estimated)");
    is($result->year, "1999");
    is($result->poster, "http://ia.media-imdb.com/images/M/MV5BMjEzNjg1NTg2NV5BMl5BanBnXkFtZTYwNjY3MzQ5._V1._SY317_CR6,0,214,317_.jpg");
    is_deeply($result->country, [ 'USA', 'Australia' ]);
    is_deeply($result->genre, [ 'Action', 'Adventure', 'Sci-Fi' ]);

    is_deeply($result->directors,
              [
                Classify::Object::Star->new(
                    url => 'http://www.imdb.com/name/nm0905152/',
                    name => 'Andy Wachowski'),
                Classify::Object::Star->new(
                    url => 'http://www.imdb.com/name/nm0905154/',
                    name => 'Lana Wachowski'),
              ]);
    is_deeply($result->stars,
              [
               Classify::Object::Star->new(
                    url => 'http://www.imdb.com/name/nm0000206/',
                    name => 'Keanu Reeves'),
                Classify::Object::Star->new(
                    url => 'http://www.imdb.com/name/nm0000401/',
                    name => 'Laurence Fishburne'),
                Classify::Object::Star->new(
                    url => 'http://www.imdb.com/name/nm0005251/',
                    name => 'Carrie-Anne Moss'),
              ]);

    $condvar->send unless $requests_count--;
}


$condvar->recv;
