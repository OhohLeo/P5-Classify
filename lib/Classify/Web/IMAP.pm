package Classify::Web::IMAP;

use strict;
use warnings;

use Data::Dumper;

use Classify::Research;

use IO::Socket::SSL;
use Moo;

has imap => (
    is => 'rw',
);

use feature 'switch';

=head2 METHODS

=over 4

=item BUILD

Initialise imap process.

=cut
sub BUILD
{
    shift->imap(Mail::IMAPClient->new(
                    User     => $user,
                    Password => $password,
                    Socket   => IO::Socket::SSL->new(
                        PeerAddr => 'imap.gmail.com',
                        PeerPort => 993,
                        SSL_verify_mode => SSL_VERIFY_NONE),
                    IgnoreSizeErrors => 1));
}

=item url

Retourne l'url du site.

=cut
sub url
{
    return 'imap.gmail.com';
}

=item info

Retourne des infos descriptives du site.

=cut
sub info
{
    return "imap.gmail.com, access to Gmail through IMAP protocol.";
}
