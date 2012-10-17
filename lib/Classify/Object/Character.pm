package Classify::Object::Character;
use parent Classify::Object;

use strict;
use warnings;

use Moo;

 has genre => (
   is => 'rw',
 );

 has quotes => (
   is => 'rw',
 );

 has found_in => (
   is => 'rw',
 );

 has played_with => (
   is => 'rw',
 );

1;
__END__
