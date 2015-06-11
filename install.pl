#!/usr/bin/env perl

use strict;
use warnings;

use v5.12;
use lib 'lib/';
use Deps;
use Data::Dumper;
use File::Fetch;
use Module::Load;

print Dumper($deps);

foreach my $module (keys $deps) {
    eval {
        load $module;
    };

    print $@;
}

