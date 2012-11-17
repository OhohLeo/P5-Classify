package Classify::Object::Image;
use parent Classify::Object;

use strict;
use warnings;

use Moo;

 has date => (
   is => 'rw',
 );

sub info
{
    return shift->SUPER::info(qw(date));
}

1;
__END__
