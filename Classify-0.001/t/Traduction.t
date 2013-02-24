use Test::More;
plan tests => 6;

use Classify::Traduction;

my $trad = Classify::Traduction->new();

is($trad->ods_file, 'etc/trad.ods');
is($trad->language, 'EN');

is_deeply($trad->get_available_languages,
          {
          'FR' => 'Français',
          'EN' => 'English'
          });

is($trad->get('Classify', 0), 'English');

is($trad->set_language('FR'), 'Français');

is($trad->get('Classify', 0), 'Français');
