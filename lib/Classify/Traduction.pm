package Classify::Traduction;

use strict;
use warnings;

use Cwd;
use File::Basename;
use File::Find;

use feature 'switch';
use feature 'say';
use Data::Dumper;

use Moo;

use constant
{
    DEFAULT_LANGAGE => 'EN',
};

has trad => (
   is => 'rw',
 );

=item $obj->BUILD([ LANGAGE ])

Permet d'initialiser la classe chargée de s'occuper des traductions.

Lorsque I<LANGAGE> n'est pas spécifiée : on choisit par défault la langue
anglaise.

=cut
sub BUILD
{
    shift->init(shift->{data} // DEFAULT_LANGAGE);
}

=item $obj->init(LANGAGE)

Permet de parcourir l'ensemble des fichiers de traduction en fonction de
I<LANGAGE>.

=cut
sub init
{
    my($self, $langage) = @_;

    unless (-d "lib/Classify/Traduction/$langage")
    {
        warn "Impossible to open & read $langage directory!"
            . " Use default langage : " . $self->DEFAULT_LANGAGE;

        $langage = $self->DEFAULT_LANGAGE;
    }

    find($self->get($langage),
         "lib/Classify/Traduction/$langage");
}

=item $obj->get(LANGAGE)

Permet de récupérer le contenu des fichiers contenant les traductions en
fonction de I<LANGAGE>.

=cut
sub get
{
    my($self, $langage) = @_;

    $self->trad({});

    return sub
    {
        my $path = getcwd() . "/$_";

        return unless -f $path or $_ =~ /\.$langage$/;

        my $filename = $_;
        $filename =~ s/\.$langage$//i;

        my $file;
        open($file, "<", $path) or die "file '$path' not found";

        binmode($file, ':encoding(UTF-8)');

        my $string;
        while (<$file>)
        {
            $string .= $_;
        }

        close $file;

        my $result = eval($string) ## no critic
            or die "'$path' has a wrong format : $@!";

        if ($File::Find::dir =~ /(Export|Import|Models)$/)
        {
            $self->trad->{$1}{$filename} = $result;
            return;
        }

        $self->trad->{$filename} = $result;
    }
}

=item $obj->translate(PATH, @PARAMS)

Permet de parcourir tous les paramètres et de remplacer les champs reconnus par
les champs traduits.

Retourne @PARAMS avec les champs traduits.

=cut
sub translate
{
    my($self, $path) = splice(@_, 0, 2);

    my $traduction = $self->trad;
    foreach my $key (split (/\//, $path))
    {
        $traduction = $traduction->{$key};

        unless (defined $traduction)
        {
            warn "Wrong traduction path file!";
            return (@_);
        }
    }

    my @params;
    foreach my $param (@_)
    {
        push(@params, $self->translate_recursive($traduction, $param));
    }

    return (@params);
}

=item $obj->translate_recursive(TRADUCTION, DATA)

Méthode appelé de manière récursive, capable de parcourir n'importe quelle
structure et de traduire les champs de ces structures.

=cut
sub translate_recursive
{
    my($self, $traduction, $data) = @_;

    for (ref $data)
    {
        when ('')
        {
            return $traduction->{$data} // $data;
        }

        when ('ARRAY')
        {
            my @params;
            foreach my $param (@$data)
            {
                push(@params, $self->translate_recursive($traduction, $param));
            }
            return \@params;
        }

        when ('HASH')
        {
            my %params;
            while (my($key, $value) = each %$data)
            {
                my $new_key =  $traduction->{$key} // $key;
                $params{$new_key} =
                    $self->translate_recursive($traduction, $value);
            }
            return \%params;
        }

        default
        {
            return $data;
        }
    }
}

1;
__END__
