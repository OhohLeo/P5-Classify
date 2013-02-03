package Classify::Web::IMDB;
use parent Classify::Web;

use strict;
use warnings;

use Data::Dumper;

use Classify::Model;

use feature 'switch';

=item url

Retourne l'url du site web.

=cut
sub url
{
    return 'http://www.imdb.com';
}

=item info

Retourne des infos descriptives du site web.

=cut
sub info
{
    return "IMDb, the world's most popular and authoritative source for movie,"
        . " TV and celebrity content.";
}

=item $obj->req(SEARCH, CB)

Permet � une I<COLLECTION> d'envoyer une requ�te de mani�re asynchrone au
I<WEBSITE> souhait�.

=cut
sub req
{
    my($self, $search, $cb) = @_;

    unless ($search =~ /^http:/)
    {
        $search = $self->url . "/find?q=" . $self->format_search($search);
    }

    $self->send('GET', $search, $cb);
}

=item $obj->rsp(URL, DATA, CB)

On re�oit ici les donn�es asynchrones : on parse ces donn�es et on les transmet
au destinataire.

=cut
sub rsp
{
    my($self, $url, $data, $cb) = @_;

    my $result;

    given ($url)
    {
        when (/find\?q=/) { $result = $self->search($data); }
        when (/title\/tt[0-9]+/) { $result = $self->movie($url, $data); }
    }

    $cb->($result);
}

=item search_page

=cut
sub search
{
    my($self, $data) = @_;

    my %result;

    # on r�cup�re tous les personnages
    $data->find('a[href^=/character/]')->each(
        sub
        {
            my $character = shift or return;

            my($name, $url) = ($character->text, $character->{href});

            return if $name eq '' or $url eq '';

            $result{character} //= [];

            push(@{$result{character}},
                 Classify::Model::->new(
                     type => 'character',
                     name => $name,
                     url  => $self->url . $url));
        });

    # on r�cup�re toutes les stars
    $data->find('a[href^=/name/]')->each(
        sub
        {
            my $star = shift or return;

            my($name, $url) = ($star->text, $star->{href});

            return if $name eq '' or $url eq '';

            $result{star} //= [];

            push(@{$result{star}},
                Classify::Model::->new(
                     type => 'star',
                     name => $name,
                     url  => $self->url . $url));
        });

    # on r�cup�re tous les films
    $data->find('a[href^=/title/]')->each(
        sub
        {
            my $movie = shift or return;

            my($name, $url) = ($movie->text, $movie->{href});

            return if $name eq '' or $url eq '';

            $result{movie} //= [];

            my $year;
            if ($movie->text_after =~ /([0-9]{4})/)
            {
                $year = $1;
            }

            my $seen_on;
            if ($movie->text_after =~ /(TV|V)/)
            {
                given ($1)
                {
                    when (/TV/) { $seen_on = 'television'; }
                    when (/V/)  { $seen_on = 'video'; }
                }
            }

            push(@{$result{movie}},
                 Classify::Model::->new(
                     type => 'movie',
                     name => $name,
                     year => $year,
                     seen_on => $seen_on,
                     url  => $self->url . $url));
        });

    return \%result;
}

=item $obj->movie

=cut
sub movie
{
    my($self, $url, $data) = @_;

    my $name = $data->find('h1')->grep(qr/class=\"header\"/)->[0]->text // undef;

    my $origin_name = $data->find('span')
        ->grep(qr/class=\"title-extra\"/)->[0]->text // undef;

    my $a = $data->find('a');

    my @directors;
    $a->grep(qr/itemprop=\"director\"/)->each(
        sub {
            my $el = shift;

            push(@directors, Classify::Model::->new(
                     type => 'star',
                     name => $el->text,
                     url  => $self->url . $el->{href}));
        });

    my @stars;
    $a->grep(qr/itemprop=\"actors\"/)->each(
        sub {
            my $el = shift;

            push(@stars, Classify::Model::->new(
                     type => 'star',
                     name => $el->text,
                     url  => $self->url . $el->{href}));
        });

    my $year = $a->grep(qr/href=\"\/year/)->[0]->text;

    my @country;
    push(@country, @{$a->grep(qr/href=\"\/country/)->pluck('text')});

    my $language = $a->grep(qr/href=\"\/language/)->[0]->text;

    my @genre;
    push(@genre, @{$a->grep(qr/href=\"\/genre\//)->pluck('text')->uniq});

    my $time = $data->find('time')->pluck('text');
    my $budget = $data->find('h4')->grep(qr/Budget/)->[0]->text_after;
    my $description = $data->find('p')->grep(qr/itemprop=\"description\"/)
        ->[0]->text;

    my $poster = $data->find('img')->grep(qr/itemprop=\"image\"/)
        ->[0]->{src};

    return Classify::Model::->new(
        type =>'movie',
        name => $name,
        url => $url,
        original_name => $origin_name,
        directors => \@directors,
        stars => \@stars,
        year => $year,
        date => $time->[0],
        description => $description,
        duration => $time->[1],
        budget => $budget,
        language => $language,
        country => \@country,
        genre => \@genre,
        poster => $poster,
        );
}

=item $obj->star

=cut
sub star
{
}

1;
__END__
