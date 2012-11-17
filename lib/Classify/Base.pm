package Classify::Base;

use strict;
use warnings;

use Carp;

=item info

Retourne des infos descriptives du site web.

=cut
sub info
{
    croak "'info' method should be defined in " . ref shift;
}

1;
__END__
