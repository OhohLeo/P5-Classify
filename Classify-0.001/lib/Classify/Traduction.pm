package Classify::Traduction;

use strict;
use warnings;

use Archive::Zip;

use Data::Dumper;

use Moo;

use constant
{
    DEFAULT_LANGUAGE => 'EN',
    DEFAULT_ODS_FILE => 'etc/trad.ods',
};

has data => (
   is => 'rw',
 );

has ods_file => (
   is => 'rw',
 );

has language => (
   is => 'rw',
 );

=head2 METHODS

=over 4

=item $obj->BUILD

=cut
sub BUILD
{
    shift->init;
}

=item $obj->init(FILE, LANGUAGE)

=cut
sub init
{
    my($self, $file, $language) = @_;

    $file //= DEFAULT_ODS_FILE;

    $self->get_data($file);

    $self->ods_file($file);
    $self->language($language // DEFAULT_LANGUAGE);
}

=item $obj->get(SHEET_NAME, NUMBER)

Get the translated value in I<SHEET_NAME> at specific I<NUMBER> of line.

=cut
sub get
{
    my($self, $sheet_name, $number) = @_;

    return ($self->data // return)->{$sheet_name}{$self->language}[$number];
}

=item $obj->get_available_languages()

Get available language list.

=cut
sub get_available_languages
{
    my $self = shift;

    my %languages;

    while (my($key, $value) = each %{($self->data // return)->{'Classify'}})
    {
        $languages{$key} = @$value[0];
    }

    return \%languages;
}

=item $obj->set_language(LANGUAGE)

Check if the language is available and set it otherwise set DEFAULT_LANGUAGE.

=cut
sub set_language
{
    my($self, $language) = @_;

    my $languages = $self->get_available_languages;

    if (exists $languages->{$language})
    {
        $self->language($language);

        return $languages->{$language};
    }

    return undef;
}

=item $obj->get_data(FILE)

Extract data from the ods I<FILE>.

If I<LANGUAGE> is used, we will only extract data with the specific language.

=cut
sub get_data
{
    my($self, $file) = @_;

    my %data;

    my $content = Archive::Zip->new($file)->contents('content.xml');

    my @sheets = split(/table:name=\"/, $content);

    # on ignore le 1er élément
    shift(@sheets);

    foreach my $sheet (@sheets)
    {
        if ($sheet =~ /^([^"]+)/)
        {
            my $row_count = 0;
            my @column_name;
            my %content;

            foreach my $row (split(/<table:table-row/, $sheet))
            {
                my $column_count = 0;

                foreach my $cell (split(/<table:table-cell/, $row))
                {
                    if ($cell =~ /<text:p>(.*)<\/text:p>/)
                    {
                        if ($row_count == 1)
                        {
                            push(@column_name, $1);
                            $content{$1} = [];
                            next;
                        }

                        push($content{$column_name[$column_count - 1]}, $1);
                    }

                    $column_count++;
                }

                $row_count++;
            }

            $data{$1} = \%content;
        }
    }

    $self->data(\%data);
}

1;
__END__
