package t::lib::Classify;

use strict;
use warnings;

use Classify;
use Classify::Collections;

use Exporter 'import';
our @EXPORT_OK = qw(classify_clean classify_restore);

=item classify_clean(IS_FIRST)

We remove all data stored.

If I<IS_FIRST> is used, we rename stored files.

=cut
sub classify_clean
{
    # if 'is_first' defined
    if (defined $_[0])
    {
	rename(Classify::STORE_CLASSIFY,
	       Classify::STORE_CLASSIFY . '.save')
	    if -f Classify::STORE_CLASSIFY;

	rename(Classify::Collections::STORE_COLLECTIONS,
	       Classify::Collections::STORE_COLLECTIONS . '.save')
	    if -f Classify::Collections::STORE_COLLECTIONS;
    }

    unlink Classify::STORE_CLASSIFY;
    unlink Classify::Collections::STORE_COLLECTIONS;
}

=item classify_restore()

We restore stored files.

=cut
sub classify_restore
{
    rename(Classify::STORE_CLASSIFY . '.save',
	   Classify::STORE_CLASSIFY)
	if -f Classify::STORE_CLASSIFY . '.save';

    rename(Classify::Collections::STORE_COLLECTIONS . '.save',
	   Classify::Collections::STORE_COLLECTIONS)
	if -f Classify::Collections::STORE_COLLECTIONS . '.save';
}

1;
__END__
