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

is_deeply($classify->get_collections_by_type('Cinema'), $cinema);

is_deeply(
    Classify::get_new_object_from_type('Collection', 'Cinema',
                                       name => 'cinema'),
    Classify::Collection::Cinema->new(name => 'cinema'));


is_deeply(Classify::get_list('import'),
          { 'Files' => 'Classify::Import::Files' });

is($classify->info_collections,
   "\nGeneric Collection :\n"
   . " - Cinema : handle, search & classify movies!\n"
   . "\taccepted configuration keys :\n"
   . "\t 'movies' = set movies extensions\n"
   . "\t 'subtitles' = set subtitles extensions\n");
