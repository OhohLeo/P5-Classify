use Test::More;
plan tests => 1;

use Classify;

my $classify = Classify->new();

is(ref $classify->collections, 'Classify::Collections');
