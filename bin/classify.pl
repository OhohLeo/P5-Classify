#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use Classify;

my(@collections, @webs, @imports, @exports, $update, $display, $help);

GetOptions(
    'collection|c=s{1,3}' => \@collections,
    'web|w=s{1,}'        => \@webs,
    'import|i=s{1,}'     => \@imports,
    'export|e=s{1,}'     => \@exports,
    'update|u=s'         => \$update,
    'display|d'          => \$display,
    'help|h'             => \$help,
) or die "Incorrect usage : try 'classify.pl -h' !\n";

if ($help)# or @ARGV == 0)
{
    die <<END;
usage : classify.pl -c see 'Collections Management'
                    -w see 'Websites Management'
                    -i see 'Imports Management'
                    -e see 'Exports Management'
                    -u see 'Update Management'
                    -t see 'Translate Management'
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

 -c delete name [ name ... ]
    Delete a collection.

 -c info
    Display all collections informations.

Websites Management : -w options

 -w name [ name ... ]
    Select one or multiple websites.

 -w test name args [ args ... ]
    Send a request to the specified website and get answer.

 -w info
    Display all websites informations.

Imports Management : -i options

 -i name args args ...
    Select one import & their arguments. See info field for arguments detailed.

 -i test name args [ args ... ]
    Send a request to the specified import and get answer.

 -i info
    Display all import sinformations.

END
}

my $classify = Classify->new(display => $display);

if (@collections)
{

    # -w info
    #    Display all websites informations.
    die $classify->info_collections(1)
        if @collections == 1 and $collections[0] eq 'info';

    # -c new name type
    #    Create a new collection.
    #    If -w option is used, you can specific websites for this type.
    #    Otherwise, a generic list specified for each collection type
    #    will be used.
    if (@collections > 2 and $collections[0] eq 'new')
    {
        # we remove 1st element
        shift @collections;

        # we check if collection name already exists
        die "Collection '" . $collections[0] . "' already exists\n"
            if defined $classify->get_collection($collections[0]);

        # we check if collection type is valid
        die 'Unexisting collection : (' . $collections[1] . ")\n"
            . 'Please choose with on this following list.'
            . $classify->info_collections
            unless Classify::check_type('Collection', $collections[1]);

        # we check if collection website is valid
        foreach my $web (@webs)
        {
            die "Unexisting website : ($web)\n"
                . "Please choose with on this following list.\n"
                . $classify->info_websites
                unless Classify::check_type('Web', $web);
        }

        # we set up the collection
        my $collection = $classify->set_collection($collections[0], @webs);
        die "Collection '" . $collection->name . "' has been created.\n"
            . $collection->info . "\n";
    }


    # -c delete name [ name ... ]
    #    Delete a collection.
    if (@collections > 1 and $collections[0] eq 'delete')
    {
        # we remove 1st element
        shift @collections;

        foreach my $collection (@collections)
        {
            print "Collection '$collection' " .
                (defined($classify->delete_collection($collection))
                ?   'removed' : 'not found') . "!\n";
        }

        exit;
    }
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
        die "Unexisting website : ($name)\n"
            . "Please choose with on this following list.\n"
            .  Classify::get_info('Web', 1)
            unless Classify::check_type('Web', $name);

        # we get the website object to make some requests
        my $web = Classify::get_new_object_from_type('Web', $name);
        my $condvar = AnyEvent->condvar;

        $web->req(join('+', @webs), sub
                   {
                       print Classify::Object::get_info(shift) . "\n";
                       $condvar->send;
                   });

        $condvar->recv;
        exit;
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

        # we check if website is valid
        die "Unexisting import : ($name)\n"
            . "Please choose with on this following list.\n"
            .  Classify::get_info('Import')
            unless Classify::check_type('Import', $name);

        # we get the website object to make some requests
        my $condvar = AnyEvent->condvar;
        my $import = Classify::get_new_object_from_type(
            'Import', $name,
            path => $imports[0],
            is_recursive => $imports[1],
            on_output => sub
            {
                my $data = shift;

                print delete($data->{name}) . ' (' . delete($data->{path}) . ")\n";

                while (my($key, $value) = each (%$data))
                {
                    print " - $key : '$value'\n";
                }

                $condvar->send;

            },
            on_stop => sub
            {
                print "Import stopped!";
                $condvar->send;
            });

        $import->launch;
        $condvar->recv;
        exit;
    }

}

# display activated : we start the program
$classify->start if defined $display;

