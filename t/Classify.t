use Test::More;
plan tests => 7;

use Classify;
use Data::Dumper;

use Classify::Collection::Cinema;

my $classify = Classify->new();

$classify->clean;

my $cinema = Classify::Collection::Cinema->new(
    name => 'cinema',
    websites => []);

is_deeply($classify->set_collection('cinema', 'Cinema'),
          $cinema);

is_deeply($classify->collections, { 'cinema' => $cinema, });

is_deeply($classify->get_collection('cinema'), $cinema);

is_deeply(
    Classify::get_new_object_from_type('Collection', 'Cinema',
                                       name => 'cinema'),
    Classify::Collection::Cinema->new(name => 'cinema'));


is_deeply(Classify::get_list('import'),
          { 'Files' => 'Classify::Import::Files' });

is($classify->info_collections,
   "\nGeneric Collection :\n"
   . " - Cinema : handle, search & classify movies!\n");

is(Classify::info_websites,
   " - IMDB : http://www.imdb.com\nIMDb, the world's most popular and authoritative source for movie, TV and celebrity content.\n");
