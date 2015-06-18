package UMBC::UserHomeRedirect;

# $Id: UserHomeRedirect.pm,v 1.1.1.1 2015/06/16 16:54:23 sda1 Exp $

use strict;
use warnings;

use Apache2::Const qw(HTTP_NOT_ACCEPTABLE HTTP_GATEWAY_TIME_OUT HTTP_NOT_FOUND REDIRECT);
use Apache2::SubRequest;
use Apache2::RequestRec;
use APR::Table;
use Net::LDAP;

# take a path... i.e. /uid1/stuff
# and redirect

use constant DIRECTORYSERVERFQDN => 'ds.umbc.edu';
use constant DIRECTORYSERVERPORT => 389;

# Connect to LDAP server and quit out if unable to connect to directory server
my $conn = Net::LDAP->new(DIRECTORYSERVERFQDN, port => DIRECTORYSERVERPORT);
$conn->bind;

sub handler {

    # Get request off command line
    my ($r, $data) = @_;

    # Get path of local file from URI
    my $path = $r->path_info();

    # Query the username and path ($1 and $2) from local file and quit out if not in correct format
    $path =~ m<^/([a-z0-9]{1,8})(/?.*?)$>;
    return HTTP_NOT_ACCEPTABLE unless $1;
    return HTTP_GATEWAY_TIME_OUT unless $conn;

    # Query LDAP for the labeledUri attribute of the given user quit out if the account or labeledUri attribute was not found
    my $account = $conn->search(
        base   => 'ou=accounts,o=umbc.edu',
        scope  => 'one',
        filter => 'uid='.$1,
        attrs  => ['labeledUri']);
    return HTTP_NOT_FOUND unless $account->entry(0) && $account->entry(0)->get_value('labeledUri');

    # Add Location header to redirect browser
    $r->headers_out->add('Location', $account->entry(0)->get_value('labeledUri').$2);
    return REDIRECT;
}

1;
__END__
