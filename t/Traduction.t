use Test::More;
plan tests => 10;

use Classify::Traduction;

my $trad = Classify::Traduction->new();
is($trad->DEFAULT_LANGAGE(), 'EN');
is($trad->{GCstar}{LangName}, 'English');


$trad = Classify::Traduction->new('FR');
is($trad->{GCstar}{LangName}, 'Fran�ais');

is_deeply($trad->translate('GCstar', 'LangName'), 'Fran�ais');

my @result;
push(@result, $trad->translate(
         'GCstar', 'LangName', 'ImagesOptionsButton',
         sub { return 'toto'; }, 'FieldsListError',
         [ 'OptionsPicturesFormatInternal', 'toto', 'OptionsFrom' ],
         { 'OptionsHistory' => [ 1, 2, 3 ],
           'key' => [ 'OptionsSMTP', 'OptionsColumns' ] }));

is($result[0], 'Fran�ais');
is($result[1], 'R�glages');
is($result[2]->(), 'toto');
is($result[3],
   'Cette liste de champs ne peut pas �tre utilis�e avec ce type de collection');
is_deeply($result[4], [ 'gcstar__', 'toto', 'E-mail exp�diteur' ]);
is_deeply($result[5], { 'Taille de l\'historique' => [ 1, 2, 3 ],
                        'key' => [ 'Serveur', 'Colonnes' ] });
