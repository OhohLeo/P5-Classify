package Classify::Object::Star;
use parent Classify::Object;

use strict;
use warnings;

use Moo;

 has nicknames => (
   is => 'rw',
 );

 has roles => (
   is => 'rw',
 );

 has born_date => (
   is => 'rw',
 );

 has death_date => (
   is => 'rw',
 );

 has born_place => (
   is => 'rw',
 );

 has death_place => (
   is => 'rw',
 );

 has images => (
   is => 'rw',
 );


1;
__END__
