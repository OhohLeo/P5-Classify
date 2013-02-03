package Classify::Base;

use strict;
use warnings;

use Moo;

use Carp;

has classify => (
   is => 'rw',
 );

=item info

Return a string that display all specific collection informations.

=cut
sub info
{
    croak "'info' method should be defined in " . ref shift;
}

=item $obj->log_great

=cut
sub log_great
{
    shift->classify->log_great(shift);
}

=item $obj->log_info

=cut
sub log_info
{
    shift->classify->log_info(shift);
}

=item $obj->log_warn

=cut
sub log_warn
{
    shift->classify->log_warn(shift);
}

=item $obj->log_critical

=cut
sub log_critic
{
    shift->classify->log_critic(shift);
}

1;
