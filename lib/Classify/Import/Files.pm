package Classify::Import::Files;
use parent Classify::Import;

use AnyEvent::AIO;
use IO::AIO;

use Moo;

use Scalar::Util;

use Classify::Research;

use feature qw(say state);

has on_recursive => (
   is => 'rw',
 );

has condvar => (
   is => 'rw',
 );

has store_research => (
   is => 'rw',
 );

state $RESEARCHES = {
    'file' =>
    Classify::Research::->new(
	name => 'file',
	data_types => {
	    name => 'text',
	    path => 'directory',
	    extension => 'text',
	    url  => 'file',
	}),
    'directory' =>
    Classify::Research::->new(
	name => 'directory',
	data_types => {
	    url  => 'directory',
	    name => 'text',
	}),
};

=head2 METHODS

=over 4

=item BUILD

=cut
sub BUILD
{
    my $self = shift;

    $self->researches($RESEARCHES);

    $self->store_research({});
}

=item info

=cut
sub info
{
    return '{ path is_recursive } - analyse directories or files.';
}

=item $obj->start(PATH[, IS_RECURSIVE, REF_COUNT, ONLY_COUNT ])

Start analyse of I<PATH>.

=cut
sub start
{
    my($self, $path, $is_recursive, $ref_count, $only_count) = @_;

    # on vérifie la présence obligatoire du path
    unless (defined $path)
    {
	$self->classify->log_warn('No path specified');
	$self->stop;

	return undef;
    }

    # on défini le callback à appeler lorsqu'on souhaite une recherche
    # récursive
    if (defined $is_recursive)
    {
	$self->on_recursive(
	    sub
	    {
		my($name, $ref_count, $only_count) = @_;

		return aio_scandir(
		    $name, 0, $self->scan_directory(
			$name, $ref_count, $only_count));
	    });
    }

    # on lance l'analyse
    $self->scan($path, $ref_count, $only_count);

    return 1;
}

=item $obj->stop()

=cut
sub stop
{
    my $self = shift;
    warn "HERE STOP";

    if (defined $self->condvar)
    {
	warn "SEND STOP";
    	$self->condvar->send;
    }

    $self->SUPER::stop;
}

=item $obj->scan(PATH[, REF_COUNT, ONLY_COUNT ])

=cut
sub scan
{
    my($self, $path, $ref_count, $only_count) = @_;

    # unless (defined $self->condvar)
    # {
    # $self->condvar(AnyEvent->condvar);
    # }

    # on initialise la valeur
    $$ref_count = 0;

    $self->store_research->{$path} =
    	aio_scandir($path, 0, $self->scan_directory(
    			$path, $ref_count, $only_count));

    $self->classify->condvar->recv;

    # on retourne le nombre d'éléments à analyser
    return $$ref_count;
}

=item $obj->scan_directory(PATH, REF_COUNT, ONLY_COUNT)

Launch files scanning through I<PATH>.

=cut
sub scan_directory
{
    my($self, $path, $ref_count, $only_count) = @_;

    return sub
    {
	my($directories, $files) = @_;

	$$ref_count += @$files;

	if (not defined $only_count)
	{
	    foreach my $name (@$files)
	    {
		my $orig_name = $name;
		my $extension;
		if ($name =~ s/\.(.*)$//)
		{
		    $extension = $1;
		}

		$self->output(
		    $RESEARCHES->{file}->new_data(
			name => $name,
			path => $path,
			extension => $extension,
			url => "$path/$orig_name"));
	    }
	}

	foreach my $name (@$directories)
	{
	    $$ref_count++;

	    if (not defined $only_count
		and $name =~ $self->filter)
	    {
		$self->output(
		    $RESEARCHES->{directory}->new_data(
			name => $name,
			url => $path,
		    ));
	    }

	    {
		# on stocke la nouvelle recherche
		$self->store_research->{"$path/$name"} =
		    ($self->on_recursive // next)->(
			"$path/$name", $ref_count, $only_count);
	    }
	}

	# on a fini l'analyse du dossier : on supprime du hash
	delete $self->store_research->{$path};

	# on a plus aucun dossier à analyser : on arrête
	$self->stop() unless keys %{$self->store_research};
    }
};

1;
__END__
