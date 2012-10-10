use Test::More;
plan tests => 10;

use Classify::Traduction;

my $trad = Classify::Traduction->new();
is($trad->DEFAULT_LANGAGE(), 'EN');
is($trad->{GCstar}{LangName}, 'English');


$trad = Classify::Traduction->new('FR');
is($trad->{GCstar}{LangName}, 'Français');

is_deeply($trad->translate('GCstar', 'LangName'), 'Français');

my @result;
push(@result, $trad->translate(
         'GCstar', 'LangName', 'ImagesOptionsButton',
         sub { return 'toto'; }, 'FieldsListError',
         [ 'OptionsPicturesFormatInternal', 'toto', 'OptionsFrom' ],
         { 'OptionsHistory' => [ 1, 2, 3 ],
           'key' => [ 'OptionsSMTP', 'OptionsColumns' ] }));

is($result[0], 'Français');
is($result[1], 'Réglages');
is($result[2]->(), 'toto');
is($result[3],
   'Cette liste de champs ne peut pas être utilisée avec ce type de collection');
is_deeply($result[4], [ 'gcstar__', 'toto', 'E-mail expéditeur' ]);
is_deeply($result[5], { 'Taille de l\'historique' => [ 1, 2, 3 ],
                        'key' => [ 'Serveur', 'Colonnes' ] });
