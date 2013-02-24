use Test::More;
plan tests => 7;

use Classify;
use Classify::Traduction;

my $classify = Classify->new(trad => 'EN');

my $trad = $classify->trad;

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
                      [ 'Importer', 1, 2, 'Exporter'],
                      { 'Edition' => 'edit',
                        'config' => 'Configuration' }]);
