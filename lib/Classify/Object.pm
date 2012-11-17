package Classify::Object;

use strict;
use warnings;

use feature 'switch';

use Moo;

 has url => (
   is => 'rw',
 );

 has name => (
   is => 'rw',
 );

sub info
{
    my $self = shift;

    my $info = $self->name . " (" . $self->url . ")\n";

    foreach my $name (@_)
    {
        if (defined (my $res = $self->$name))
        {
            $info .= " - $name : " . get_info($res) . "\n";
        }
    }

    return $info;
}

=item info_detail

Détaille le contenu de la réponse.

=cut
sub get_info
{
    my $result = shift;

    my $info;

    for (ref $result)
    {
        when ('HASH')
        {
            while (my($key, $value) = each %$result)
            {
                $info .= "$key : " . info_detail($value) . "\n";
            }

            return substr($info, 0, -3);
        }

        when ('ARRAY')
        {
            foreach my $value (@$result)
            {
                $info .= info_detail($value) . " ";
            }

            return substr($info, 0, -1);
        }

        when (/Classify::Object/)
        {
            return $result->info;
        }

        default
        {
            return $result;
        }
    }
}

1;
__END__

