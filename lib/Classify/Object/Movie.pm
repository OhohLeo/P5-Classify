package Classify::Object::Movie;
use parent Classify::Object;

use strict;
use warnings;

use Moo;

 has original_name => (
   is => 'rw',
 );

 has translate_name => (
   is => 'rw',
 );

 has other_names => (
   is => 'rw',
 );

 has year => (
   is => 'rw',
 );

 has date => (
   is => 'rw',
 );

 has country => (
   is => 'rw',
 );

 has language => (
   is => 'rw',
 );

 has genre => (
   is => 'rw',
 );

has seen_on => (
    is => 'rw',
);

 has directors => (
   is => 'rw',
 );

 has writers => (
   is => 'rw',
 );

 has stars => (
   is => 'rw',
 );

 has poster => (
   is => 'rw',
 );

 has images => (
   is => 'rw',
 );

 has budget => (
   is => 'rw',
 );

 has duration => (
   is => 'rw',
 );

 has aspect_ratio => (
   is => 'rw',
 );

 has color => (
   is => 'rw',
 );

 has description => (
    is => 'rw',
    );

sub info
{
    return shift->SUPER::info(
        qw(original_name translate_name other_names year date country language genre
          seen_on directors writers stars poster images budget duration aspect_ratio
          color description));
}

1;
__END__
