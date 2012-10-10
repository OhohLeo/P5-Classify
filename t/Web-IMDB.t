use Test::More;
plan tests => 1;

use Classify::Web::IMDB;

my $condvar = AnyEvent->condvar;

my $imdb = Classify::Web::IMDB::->new;

$imdb->request('Matrix',
               sub
               {
                   warn "here!";
                   $condvar->send;
               });

$condvar->recv;
