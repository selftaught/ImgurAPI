#!/usr/bin/env perl

package ImgurAPI::MockupServer;

use strict;
use warnings;

use HTTP::Daemon;
use HTTP::Response;
use IO::File;
use Template;

END {
    __PACKAGE__->stop_server();
}

sub start_server : method {
    my $self    = shift;
    my $port    = shift;
    my $action  = shift;
    my %actions = ($action && ref($action) eq 'HASH' ? ); 
}

1;
