package Classify::Traduction;
use parent Classify::Base;

use strict;
use warnings;

use Archive::Zip;

use Data::Dumper;

use Moo;

use feature 'switch';

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

=item $obj->BUILD()

=cut
sub BUILD
{
    shift->init;
}


=item $obj->info()

=cut
sub info
{
    my $languages = shift->get_available_languages;

    my $info = 'List of available traductions :';
    while (my($key, $language) = each %$languages)
    {
        $info .= "\n - $language\t: use '$key' input language";
    }

    return "$info\n";
}

=item $obj->init(FILE, LANGUAGE)

=cut
sub init
{
    my($self, $file, $language) = @_;

    $file //= DEFAULT_ODS_FILE;

    $self->get_data($file);

    $self->ods_file($file);

    $language //= $self->language;

    my $languages = $self->get_available_languages;
    if (defined $language and exists $languages->{$language})
    {
        $self->language($language);
        return;
    }

    $self->language($self->classify->save->{trad} // DEFAULT_LANGUAGE);
}

=item $obj->get_available_languages()

Get available language list.

=cut
sub get_available_languages
{
    return (shift->data // return)->{'Classify'}{'Language'};
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
        $self->log_info("Use $language language.");

        $self->language($language);

        $self->classify->save_classify('trad', $language);

        return $languages->{$language};
    }

    $self->log_critic("Impossible to set '$language'! Set default language.");

    $self->language(DEFAULT_LANGUAGE);

    return undef;
}

=item $obj->get(SHEET_NAME, NAME)

Get the translated value in I<SHEET_NAME> with specific key I<NAME>.

=cut
sub get
{
    my($self, $sheet_name, $name) = @_;

    return ($self->data // return)->{$sheet_name}{$name}{$self->language};
}

=item $obj->translate(SHEET_NAME, STRUCTURE)

Get the translated structure based on I<SHEET_NAME>

=cut
sub translate
{
    my($self, $sheet_name) = splice(@_, 0, 2);

    my @params;

    foreach my $param (@_)
    {
        push(@params, $self->translate_recursive(
                 $sheet_name, $param // next));
    }

    return (@params);
}

=item $obj->translate_recursive(TRADUCTION, DATA)

Recursive method to translate recursively all possible structure.

=cut
sub translate_recursive
{
    my($self, $sheet_name, $data) = @_;

    for (ref $data)
    {
        when ('')
        {
            return $self->get($sheet_name, $data) // $data;
        }

        when ('ARRAY')
        {
            my @params;
            foreach my $param (@$data)
            {
                push(@params, $self->translate_recursive($sheet_name, $param));
            }
            return \@params;
        }

        when ('HASH')
        {
            my %params;
            while (my($key, $value) = each %$data)
            {
                my $new_key =  $self->get($sheet_name, $key) // $key;
                $params{$new_key} =
                    $self->translate_recursive($sheet_name, $value);
            }

            return \%params;
        }

        default
        {
            return $data;
        }
    }
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
                my $type;

                foreach my $cell (split(/<table:table-cell/, $row))
                {
                    if ($cell =~ /<text:p>(.*)<\/text:p>/)
                    {
                        if ($row_count == 1)
                        {
                            push(@column_name, $1);
                            next;
                        }

                        if ($column_count == 1)
                        {
                            $type = $1;
                        }
                        else
                        {
                            $content{$type}{$column_name[$column_count - 2]} = $1;
                        }
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
