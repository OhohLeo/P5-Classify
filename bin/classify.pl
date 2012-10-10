#!/usr/bin/perl

use strict;
use warnings;

my $VERSION = '2.0.0';

use Getopt::Long;
use Classify;

sub usage
{
    print "Usage: $0 [-u UPDATE-OPTIONS] [-x EXECUTE-OPTIONS] [FILENAME]

Launch GCstar, a personal collection manager. Without any option, it will open
FILENAME if specified or the previously opened file.

Update options:

  -u, --update                 Tell GCstar to look for available updates
  -a, --all                    Update all components
  -c, --collection             Update collection models
  -w, --website                Update plugins to download information
  -i, --import                 Update plugins to import data
  -e, --export                 Update plugins to export data
  -l, --lang                   Update translations
  -n, --noproxy                Don't ask for a proxy

Execute options:

  -x, --execute                Enter non-interactive mode
  -c, --collection MODEL       Specify the collection type
  -w, --website PLUGIN         Specify the plugin to use to download information
  -i, --import PLUGIN          Specify the plugin to use to import a collection
  -e, --export PLUGIN          Specify the plugin to use to export the collection
  -f, --fields FILENAME        File containing fields list to use for import/export
  -o, --output FILENAME        Write output in FILENAME instead of standard output
  --download TITLE             Search for the item with TITLE as name
  --importprefs PREFERENCES    Preferences for the import plugin
  --exportprefs PREFERENCES    Preferences for the export plugin
  --list-plugins               List all the plugins available to download information

  Preferences for import/export plugins are specified using this schema:
    \"Key1=>Value1,Key2=>Value2\"

Environment variables:

  \$HOME                        Used to define following variables if needed
  \$XDG_CONFIG_HOME             Where configuration files should be stored
                                  If not defined: \$HOME/.config
  \$XDG_DATA_HOME               Where some data will be stored
                                  If not defined: \$HOME/.local/share

Bugs reporting:

  To report bugs, please use this forum:
    http://forums.gcstar.org/viewforum.php?id=4

";
}

Classify->new(@ARGV);
