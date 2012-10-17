use Test::More;
plan tests => 14;

use Classify::Web::IMDB;

use Data::Dumper;

my $condvar = AnyEvent->condvar;

my $imdb = Classify::Web::IMDB::->new;

my $requests = 1;

$imdb->req('Matrix',
           sub
           {
               my $result = shift;

               is(exists($result->{character}), 1);
               is(exists($result->{star}), 1);
               is(exists($result->{movie}), 1);

               my $first_character = $result->{character}[0];

               is(ref $first_character,  Classify::Object::Character);
               is($first_character->name, 'Matrix');
               is($first_character->url,
                  'http://www.imdb.com/character/ch0029474/');


               my $first_star = $result->{star}[0];

               is(ref $first_star,  Classify::Object::Star);
               is($first_star->name, 'Marco Materazzi');
               is($first_star->url,
                  'http://www.imdb.com/name/nm2309403/');

               my $first_movie = $result->{movie}[0];

               is(ref $first_movie,  Classify::Object::Movie);
               is($first_movie->name, 'Matrix');
               is($first_movie->year, 1999);
               is($first_movie->seen_on, undef);
               is($first_movie->url,
                  'http://www.imdb.com/title/tt0133093/');

               $condvar->send unless (--$requests);
           });

$imdb->req('http://www.imdb.com/title/tt0133093/',
           sub
           {
               my $result = shift;

               warn Dumper($result);

               $condvar->send unless (--$requests)
           });


$condvar->recv;
