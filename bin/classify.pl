#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use Classify;
use Classify::Tools 'check_type';
use Classify::Console;
use Classify::Traduction;
use Classify::Display::Classify;
use Classify::Display::Import;

use Data::Dumper;

my(@collections, @webs, $filter, @imports, @exports, $update, $display, $trad,
   $help);

GetOptions(
    'collection|c=s{1,}' => \@collections,
    'web|w=s{1,}'        => \@webs,
    'filter|f=s'         => \$filter,
    'import|i=s{1,}'     => \@imports,
    'export|e=s{1,}'     => \@exports,
    'trad|t=s'           => \$trad,
    'update|u=s'         => \$update,
    'display|d'          => \$display,
    'help|h'             => \$help,
) or die "Incorrect usage : try 'classify.pl -h' !\n";

if ($help)
{
    die <<END;
usage : classify.pl -c see 'Collections Management'
                    -w see 'Websites Management'
                    -f see 'Filter Management'
                    -i see 'Imports Management'
                    -e see 'Exports Management'
                    -t see 'Traduction Management'
                    -d activate graphic application
                    -h this help.

Collections Management : -c options

 -c name [ name ... ]
    Select one or multiple collections.

 -c new name type
    Create a new collection.
    If -w option is used, you can specific websites for this type.
    Otherwise, a generic list specified for each collection type
    will be used.

 -c config name key value [ value ... ]
    Configure a specified collection.
    The name could be a generic collection name (all collections of
    that type will be impacted) or an already existing collection.
    Collection info will display what keys can be configured.

 -c clean name [ name ... ]
    Clean all elements of a collection.
    WARNING : you can choose 'all' to clean all collections.

 -c delete name [ name ... ]
    Delete a collection.
    WARNING : you can choose 'all' to remove all collections.

 -c info
    Display all collections informations.

Websites Management : -w options

 -w name [ name ... ]
    Select one or multiple websites.

 -w test name args [ args ... ]
    Send a request to the specified website and get answer.

 -w info
    Display all websites informations.

Filter Management : -f option

 -f regular_expression
    Accept only data that match the regular expression setted.

Imports Management : -i options

 -i name args args ...
    Select one import & their arguments. See info field for arguments detailed.

 -i test name args [ args ... ]
    Send a request to the specified import and get answer.

 -i info
    Display all import informations.

Traduction Management : -t options

 -i language
    Set the specific language ('EN' by default).

 -i info
    Display all traduction informations.

END
}



my $classify;
if (defined $display)
{
    $classify = Classify::Display::Classify->new(trad => $trad);
}
else
{
    $classify = Classify->new(trad => $trad);
}

my $condvar = AnyEvent->condvar;

# we set the filter if it is not used.
$filter //= '';

if ($trad)
{
    # -w info
    #    Display traduction lists.
    die  "Traduction list : \n" . $classify->trad->info
        if $trad eq 'info'
        or not $classify->trad->set_language($trad);
}

if (@webs)
{
    # -w info
    #    Display all websites informations.
    die  "Websites list : \n" . Classify::get_info('Web', 1)
        if @webs == 1 and $webs[0] eq 'info';

    # -w test name args [ args ... ]
    #    Send a request to the specified website and get answer.
    if (@webs > 2 and $webs[0] eq 'test')
    {
        # we remove 1st element
        shift @webs;

        my $name = shift @webs;

        # we check if website is valid
        exit_warn("Unexisting website : ($name)\n"
            . "Please choose with on this following list.\n"
            .  Classify::get_info('Web', 1))
            unless Classify::Tools::check_type('Web', $name);

        # we get the website object to make some requests
        my $web = $classify->create_object_from_type('Web', $name);

        $web->req(join('+', @webs), sub
                   {
                       $classify->log_info(shift->info);
                       $condvar->send;
                   });

        $condvar->recv;
        exit;
    }

    # we get web objects and we replace by the string list
    my @web_objects;
    foreach my $web (@webs)
    {
        push(@web_objects,
             $classify->create_object_from_type('Web', $web)
             // exit_warn("Web '$web' not found!"));
    }

    @webs = @web_objects;
}

if (@collections)
{
    # -w info
    #    Display all collections informations.
    die $classify->collections->info(1)
        if @collections == 1 and $collections[0] eq 'info';

    # -c new name type
    #    Create a new collection.
    #    If -w option is used, you can specific websites for this type.
    #    Otherwise, a generic list specified for each collection type
    #    will be used.
    if ($collections[0] eq 'new')
    {
        if (defined $display)
        {
            $classify->collection->add_display(
                sub
                {
                    Gtk2->main_quit;
                });

            Gtk2->main;
            exit_great('Collection has been created.');
        }
        elsif (@collections > 2)
        {
            # we remove 1st element
            shift @collections;

            # we check if collection type is valid
            exit_warn('Unexisting collection (Classify::Collection::'
		      . $collections[1] . ')')
                unless Classify::Tools::check_type('Collection', $collections[1]);

            # we check if collection website is valid
            foreach my $web (@webs)
            {
                exit_warn("Unexisting website : ($web)\n"
                          . "Please choose with on this following list.\n"
                          . $classify->info_websites)
                    unless Classify::Tools::check_type('Web', $web);
            }

            # we set up the collection
            my $collection = $classify->collections->add(
                $collections[0], $collections[1], @webs);

            exit unless defined $collection;

            exit_great("Collection '" . $collection->name
                       . "' has been created!");
        }
    }

    # -c config name key value [ value ... ]
    #    Configure a specified collection.
    #    The name could be a generic collection name (all collections of
    #    that type will be impacted) or an already existing collection.
    #    Collection info will display what keys can be configured.
    if (@collections > 1 and $collections[0] eq 'config')
    {
        # we remove 1st element
        shift @collections;

        # we get the name or the type of the collection
        my $name = shift @collections;

        # we search for valid collections
        my @collection_list =
            $classify->collections->get_by_type($name)
            || $classify->collections->get($name);

        exist_warn("Unexisting collection : ($name)\n"
            . 'Please choose with on this following list.'
            . $classify->collections->info)
            unless @collection_list;

        my $key = shift @collections;

        # we set the keys for each collections
        foreach my $collection (@collection_list)
        {
            my $method;
            unless(defined($method = $collection->can("config_$key")))
            {
                exit_warn("Unexisting key configuration : ($key)\n"
                    . 'Please choose with on this following list.'
                    . $classify->collections->info);
            }

            $collection->$method(@collections > 0 ? \@collections : undef);
            $classify->collections->save;
            exit_great("'$key' configuration set!\n");
        }
    }

    # -c clean name [ name ... ]
    # Clean all elements of a collection.
    if (@collections > 1 and $collections[0] eq 'clean')
    {
        # we remove 1st element
        shift @collections;

        foreach my $collection (@collections)
        {
	    $classify->collections->clean($collection);
            defined($classify->collections->get($collection))
                ? $classify->log_great("Collection '$collection' cleaned!")
                : $classify->log_warn("Collection '$collection' not found!");
        }

        exit;
    }

    # -c delete name [ name ... ]
    #    Delete a collection.
    if (@collections > 1 and $collections[0] eq 'delete')
    {
        # we remove 1st element
        shift @collections;

        @collections = keys %{$classify->collections}
           if $collections[0] eq 'all';

        foreach my $collection (@collections)
        {
	    defined($classify->collections->get($collection))
                ? $classify->log_great("Collection '$collection' deleted!")
                : $classify->log_warn("Collection '$collection' not found!");

            $classify->collections->delete($collection);
	}

        exit;
    }

    # on affiche les collections
    my @collection_objects;
    foreach my $collection (@collections)
    {
        $collection =
            $classify->collections->get($collection)
            // exit_warn("Collection '$collection' not found!");

        # update websites if needed.
        $collection->websites(@webs) if @webs;

        push(@collection_objects, $collection);
    }
}

if (@imports)
{
    # -i info
    #    Display all imports informations.
    die Classify::get_info('Import')
        if @imports == 1 and $imports[0] eq 'info';

    # -w test name args [ args ... ]
    #    Send a request to the specified website and get answer.
    if (@imports > 2 and $imports[0] eq 'test')
    {
        # we remove 1st element
        shift @imports;

        my $name = shift @imports;

        # we check if import is valid
        exit_warn("Unexisting import : ($name)\n"
            . "Please choose with on this following list.\n"
            .  Classify::get_info('Import'))
            unless Classify::Tools::check_type('Import', $name);

        my $import = $classify->create_object_from_type(
            'Import', $name,
            filter       => qr/$filter/,
            condvar      => $condvar,
            on_output    => sub
            {
		$classify->log_info(shift->info);
            },
            on_stop      => sub
            {
                $classify->log_great("Import stopped!\n");
                $condvar->send;
            });

        if (defined $display)
	{
	    $import = Classify::Display::Import::->new(
		handle_import => $import,
		classify => $classify);
	}

	warn "CALL START HERE!";
        if ($import->start(@imports))
	{
	    $condvar->recv;
	}

        $classify->collections->save;
        exit;
    }

    # -i name args args ...
    # Select one import & their arguments. See info field for arguments
    # detailed.
    my $name = shift @imports;

    # we check if import is valid
    exit_warn("Unexisting import : ($name)\n"
        . "Please choose with on this following list.\n"
        .  Classify::get_info('Import'))
        unless Classify::Tools::check_type('Import', $name);

    # we get the website object to make some requests
    my $import = $classify->create_object_from_type(
        'Import', $name,
        path => $imports[0],
        filter=> qr/$filter/,
        is_recursive => $imports[1],
        on_output => sub
        {
            my $input = shift;

            foreach my $collection (@collections)
            {
                $collection->input($input);
            }
        },
        on_stop => sub
        {
	    warn "HERE!";
            $classify->log_great("Import stopped!\n");
            $condvar->send unless @webs;
        });


    if (defined $display)
    {
	$import = Classify::Display::Import::->new(
	    handle_import => $import,
	    classify => $classify);
    }

    my $console;
    foreach my $collection (@collections)
    {
        $collection->handle_result(
            sub
            {
                $console->on_input($collection, shift);
            });
    }


    $import->start;

    if (@webs)
    {
        $console = Classify::Console::->new(
            on_stop => sub
            {
                # we stop import process
                $import->stop();

                # we stop websites process

                $condvar->send;
            });

        # we do not display logs while console is up
        #$classify->no_log(1);

        # we launch the console
        $console->launch;
    }

    $condvar->recv;
    $classify->collections->save;
    exit;
}

# display activated : we start the program
$classify->start if defined $display;

sub exit_great
{
    $classify->log_great(shift);
    exit;
}

sub exit_warn
{
    $classify->log_warn(shift);
    exit
}

sub import_display
{
    my $import = shift;

    $import->set_display(
        trad => Classify::Traduction::->new(
	    data => 'FR',
	    classify => $classify,
	),
        on_stop => sub
        {
            $import->display(undef);
            $import->stop();
        });
}
