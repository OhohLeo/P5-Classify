use Test::More;
plan tests => 11;

use t::lib::Classify qw(classify_clean classify_restore);

use Term::ANSIColor qw(:constants);

sub check_exec
{
    my($type, $args, $expected) = @_;

    is(`bin/classify.pl -$type $args 2>&1`, $expected);
}

BEGIN
{
    # we save & clean the project
    classify_clean(1);
}

END
{
    # we restore the project
    classify_restore();
}

################################
# we test Collections Management
################################

# we check all collections : none exists
check_exec('c', 'info',
"No Collection Found!

Generic Collection :
 - Cinema : Handle, Search & Classify Movies!
	 configuration keys =
	  'movies' = set movies extensions
	  'subtitles' = set subtitles extensions
");

# we select a collection that doesn't exist
check_exec('c', 'failed_test',
	   YELLOW . "Collection 'failed_test' not found!" . RESET . "\n");

# we create a new collection : invalid type
check_exec('c', 'new test Test',
	   YELLOW . "Unexisting collection (Classify::Collection::Test)"
	   . RESET . "\n");

# we create a new collection : success
check_exec('c', 'new test Cinema',
	   GREEN . "Collection 'test' has been created!" . RESET . "\n"
   );

# we check the new collection is displayed
check_exec('c', 'info',
"Collection List :
 - test :
	researches = subtitle, movie
	websites = none!

Generic Collection :
 - Cinema : Handle, Search & Classify Movies!
	 configuration keys =
	  'movies' = set movies extensions
	  'subtitles' = set subtitles extensions
");

# we clean the collection
check_exec('c', 'clean test',
	   GREEN . "Collection 'test' cleaned!" . RESET . "\n");

check_exec('c', 'clean failed_test',
	   YELLOW . "Collection 'failed_test' not found!" . RESET . "\n");

# we delete the collection
check_exec('c', 'delete test',
	   GREEN . "Collection 'test' deleted!" . RESET . "\n");

check_exec('c', 'delete failed_test',
	   YELLOW . "Collection 'failed_test' not found!" . RESET . "\n");

# we check all collections : none exists
check_exec('c', 'info',
"No Collection Found!

Generic Collection :
 - Cinema : Handle, Search & Classify Movies!
	 configuration keys =
	  'movies' = set movies extensions
	  'subtitles' = set subtitles extensions
");

################################
# we test Import Management
################################

# we check all imports information
check_exec('i', 'info',
" - Files : { path is_recursive } - analyse directories or files.
");
