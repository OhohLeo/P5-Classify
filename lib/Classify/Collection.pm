package Classify::Collection;
use parent Classify::Base;

use strict;
use warnings;

use Carp;

use Moo;

use Data::Dumper;

has name => (
   is => 'rw',
 );

has websites => (
   is => 'rw',
 );

has exports => (
   is => 'rw',
 );

=item $obj->get_info

Retourne toutes les infos descriptives de n'importe quelle collection.

=cut
sub get_info
{
    my $self = shift;

    my $result;
    $result .= "\nWeb : ";
    $result .= "none!\n" unless @{$self->websites};
    foreach my $web (@{$self->websites})
    {
        $result .= ref $web . ", ";
    }

    if (defined(my $imports = $self->imports))
    {
        $result .= "\nImport : ";
        $result .= "none!\n" unless @$imports;
        foreach my $import (@$imports)
        {
            $result .= ref $import . ", ";
        }
    }

    if (defined(my $exports = $self->exports))
    {
        $result .= "\nExport : ";
        $result .= "none!\n" unless @$exports;
        foreach my $export (@$exports)
        {
            $result .= ref $export . ", ";
        }
    }

    return $result;
}

=item $obj->input

On g�re ici le type d'entr�e de la collection choisie.

=cut
sub input
{
    warn 'In collection ' . ref(shift) . 'Data not handled : '
        . Dumper(\@_);
}

=item $obj->feed_exports(INPUT, INPUT, ...)

Une fois les donn�es analys�es : on les envoie aux gestionnaires d'exportation.

=cut
sub feed_exports
{
    my($self, @input) = @_;

    return unless defined $self->exports;

    foreach my $export (@{$self->exports})
    {
        $export->input(@input);
    }
}

1;
__END__
