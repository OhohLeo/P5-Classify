package Classify::Base;

use strict;
use warnings;

use Moo;
use Carp;

=head1 Classify::Base

=cut
has classify => (
   is => 'rw',
 );

=head2 MANDATORY METHOD

=over 4

=item info

Return a string that display all specific collection informations.

=cut
sub info
{
    croak "'info' method should be defined in " . ref shift;
}

=back

=head2 LOGGER METHODS

Method used to display current informations.

=over 4

=item $obj->log_great
=item $obj->log_info
=item $obj->log_warn
=item $obj->log_critical

=cut
BEGIN
{
    no strict;

    for (qw(great info warn critical))
    {
        my $method = 'log_' . $_;
        *$method = sub { shift->classify->$method(shift)  };
    }
}


=back

=head2 STATISTIC METHODS

Methods used to search informations inside strings, to compare strings & models
and find similarities.

=over 4

=cut

1;
__END__

=back

=head2 ATTRIBUT
=over 4

=head2 AUTHOR

Léo Martin - lmartin.leo@gmail.com

=cut

