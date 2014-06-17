use Test::More;
plan tests => 14;

use t::lib::Classify qw(classify_clean classify_restore);

use Classify;
use Classify::Collections;
use Classify::Collection;

use constant TEST_COLLECTION => 'lib/Classify/Collection/Test.pm';

my $filehandle;

BEGIN
{
    # we save & clean the project
    classify_clean(1);

    # we create the collection for the test
    open($filehandle, '>', TEST_COLLECTION)
	or die "Impossible to create '" . TEST_COLLECTION . "'";

    # we write content
    print $filehandle <<TEST_COLLECTION_END;
package Classify::Collection::Test;
use parent Classify::Collection;

sub info
{
    return 'Test a simple collection!';
}
1;
__END__
TEST_COLLECTION_END

    # we close the file
    close($filehandle);
}

END
{
    # we remove test collection
    unlink TEST_COLLECTION;

    # we restore the project
    classify_restore();
}

my $classify = Classify->new();

my $collections = Classify::Collections::->new(classify => $classify);

my $collection1 = Classify::Collection::->new(
    classify => $classify,
    name => 'test1',
    handle_result => undef,
    websites => undef);

my $collection2 = Classify::Collection::->new(
    classify => $classify,
    name => 'test2',
    handle_result => undef,
    websites => undef);

# we test 'add'
is_deeply($collections->add('test1', 'Test'), $collection1);
is_deeply($collections->add('test2', 'Test'), $collection2);
is_deeply($collections->collections,
	  {
	      test1 => $collection1,
	      test2 => $collection2
	  });

# we test 'get'
is_deeply($collections->get('test'), undef);
is_deeply($collections->get('test1'), $collection1);
is_deeply($collections->get('test2'), $collection2);

my @collections = $collections->get('test1', 'test2');
is_deeply(\@collections, [ $collection1, $collection2 ]);

# we reset collection list
@collections = ();

# we test 'get_by_type'
@collections = $collections->get_by_type('Test');
is_deeply(\@collections, [ $collection1, $collection2 ]);

# we test 'clean'
$collections->collections->{test1}->imported->{test} = 'test';
$collections->collections->{test2}->classified->{test} = 'test';

$collections->clean('test', 'test1', 'test2');
is_deeply($collections->collections->{test1}->classified, {});
is_deeply($collections->collections->{test1}->imported, {});
is_deeply($collections->collections->{test2}->classified, {});
is_deeply($collections->collections->{test2}->imported, {});

# we test 'delete'
$collections->delete('test', 'test1', 'test2');
is_deeply($collections->collections, {});

is($classify->collections->info,
<<TEST_INFO_COLLECTION

Generic Collection :
 - Cinema : Handle, Search & Classify Movies!
	 configuration keys =
	  'movies' = set movies extensions
	  'subtitles' = set subtitles extensions
 - Test : Test a simple collection!
TEST_INFO_COLLECTION
);
