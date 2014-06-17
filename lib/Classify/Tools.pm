package Classify::Tools;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(check_type get_info get_list);

use Class::Inspector;
use File::Find;

=head2 METHODS

=over 4

=item check_type(PLUGIN_DIRECTORY, TYPE)

Return 1 if the specified type with the plugin choosed exists, undef otherwise.

=cut
sub check_type
{
    my($plugin, $type) = @_;

    return undef unless -d "lib/Classify/$plugin";

    my $class = "Classify::$plugin\::$type";

    eval "require $class";

    return $@ ? undef : 1;
}

=item get_list(PLUGIN_DIRECTORY)

Return hash specifying list of plugins found :
{ 'plugin name' => 'plugin path' }.

=cut
sub get_list ($)
{
    my $plugin = ucfirst shift;

    my %store;

    finddepth(sub
         {
             my $name = $_;

             $name =~ s/\.pm$//;

        die $@ if $@;

        $result .= " - $name : "
            . ($with_url ? $class->url : '')
            . $class->info . "\n";
    }

    return $result;
}

1;
__END__
