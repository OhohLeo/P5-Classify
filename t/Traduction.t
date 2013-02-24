use Test::More;
plan tests => 7;

use Classify::Traduction;

my $trad = Classify::Traduction->new();

is($trad->ods_file, 'etc/trad.ods');
is($trad->language, 'EN');

is_deeply($trad->get_available_languages,
          {
          'FR' => 'Français',
          'EN' => 'English'
          });

is($trad->get('Classify', 'Language'), 'English');

is($trad->set_language('FR'), 'Français');

is($trad->get('Classify', 'Language'), 'Français');

my @result = $trad->translate(
    'Classify', MenuFile, 'toto',
    [ 'MenuImport', 1, 2, 'MenuExport' ],
    { 'MenuEdit' => 'edit', 'config' => 'MenuConfiguration' });

is_deeply(\@result, [ 'Fichier', 'toto',
                      [ 'importer', 1, 2, 'exporter'],
                      { 'Edition' => 'edit',
                        'config' => 'Configuration' }]);
