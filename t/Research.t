use Test::More;
plan tests => 2;

use Classify::Research;

my $research = Classify::Research->new(
    name => 'test',
    data_types =>
    {
	text   => 'text',
	markup => 'markup',
	int    => 'int',
	double => 'double',
	bool   => 'bool',
	scalar => 'scalar',
	pixbuf => 'pixbuf',
    });

is($research->name, 'test');

my $data = $research->new_data(
    text   => 'text',
    markup => 'not_handled',
    int    => 123,
    double => 'not_handled',
    bool   => 1,
    scalar => 'This is a test',
    pixbuf => 'not_handled');

my @get = $data->get(qw(text markup int double bool scalar pixbuf));
is_deeply(\@get, [ 'text', undef, 123, undef, 1, 'This is a test', undef ]);
