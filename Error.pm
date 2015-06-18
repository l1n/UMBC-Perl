package UMBC::Error;

use strict;
use warnings;
use Apache2::Const qw(:http OK);
use Apache2::RequestRec;
use Apache2::RequestIO;
use APR::Table;

my %errorHash = (
    404 => {
        short => 'Not Found',
        long  => 'The requested URL #REDIRECT_URL was not found on this server.'
    }, 
    500 => {
        short => 'Internal Server Error',
        long  => 'The server encountered an internal error or misconfiguration while processing the requested URL #REDIRECT_URL.'
    }
);

my $helpText = 'If you continue to have problems, please <a href="https://rt.umbc.edu/UMBC/RequestHelp.html">submit a help request</a> or contact the Technology Support Center at 410-455-3838.';

sub handler {
    my ($r, $data) = @_;
    my $errorCode = $ENV{PATH_INFO};
    my $server = $ENV{SERVER_NAME};
    my $port = $ENV{SERVER_PORT};

    $errorCode =~ s<^/(\d\d\d).*$><$1>;
    my $short = $errorHash{$errorCode}{short};
    my $long = $errorHash{$errorCode}{long};
    $long =~ s<#([A-Z_]*)><$ENV{$1}>eg;

    my $header = qq{
    <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
    <html><head>
    <title>$errorCode $short</title>
    </head><body>
    <h1>$short</h1>
    };

    my $body = qq{
    <p>$long</p>
    <p>$helpText</p>
    };

    my $footer = qq{
    <hr>
    <address>$server Port $port</address>
    <pre>
};
    if ($ENV{DEBUG}) {
        $footer .= "$_ => $ENV{$_}\n" foreach keys %ENV;
    }
    $footer .= qq{
    </pre>
    </body></html>
    };

    $r->headers_out->add('Status', $ENV{REDIRECT_STATUS}." Condition Intercepted");
    $r->print($header);
    $r->print($body);
    $r->print($footer);
    $r->rflush();
    return OK;
}

1;
__END__