#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use Classify;

my(@collection, @web, $import, $export, $update, $display, $help);

GetOptions(
    'collection|c=s{1,3}' => \@collection,
    'web|w=s{1,}'        => \@web,
    'import|i=s'         => \$import,
    'export|e=s'         => \$export,
    'update|u=s'         => \$update,
    'display|d'          => \$display,
    'help|h'             => \$help,
) or die "Incorrect usage : try 'classify.pl -h' !\n";

if ($help)
{
    die <<END;
usage : classify.pl -c see 'Collection Management'
                    -w see 'Websites Management'
                    -i import name, args ...
                    -e export name, args ...
                    -u update program
                    -d activate display
                    -h this help.

Collection Management : -c options

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

 -c name [ name ... ]
    Select one or multiple websites.

 -w name args [ args ... ]
    Send a request to the specified website and get answer.

 -w info
    Display all websites informations.

END
}

my $classify = Classify->new(display => $display);

if (@collection)
{
    die $classify->info_collections(1)
        if @collection == 1 and $collection[0] eq 'info';

    if (@collection > 2 and $collection[0] eq 'new')
    {
        # we remove 1st element
        shift @collection;

        # we check if collection name already exists
        die "Collection '" . $collection[0] . "' already exists\n"
            if defined $classify->get_collection($collection[0]);

        # we check if collection type is valid
        die 'Unexisting collection : (' . $collection[1] . ")\n"
            . 'Please choose with on this following list.'
            . $classify->info_collections
            unless Classify::check_type('Collection', $collection[1]);

        # we check if collection website is valid
        foreach my $web (@web)
        {
            die "Unexisting website : ($web)\n"
                . "Please choose with on this following list.\n"
                . $classify->info_websites
                unless Classify::check_type('Web', $web);
        }

        # we set up the collection
        my $collection = $classify->set_collection(@collection, @web);
        die "Collection '" . $collection->name . "' has been created.\n"
            . $collection->info . "\n";
    }

    if (@collection > 1 and $collection[0] eq 'delete')
    {
        # we remove 1st element
        shift @collection;

        foreach my $collection (@collection)
        {
            print "Collection '$collection' " .
                (defined($classify->delete_collection($collection))
                ?   'removed' : 'not found') . "!\n";
        }

        exit;
    }
}

if (@web)
{
    die  "Websites list : \n" . $classify->info_websites
        if @web == 1 and $web[0] eq 'info';
}

# display activated : we start the program
$classify->start if defined $display;

