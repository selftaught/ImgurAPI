#!/usr/bin/env perl

use strict;
use warnings;
use TAP::Harness;

my $harness = TAP::Harness->new({
    'verbosity' => 1,
    'lib'       => ['lib', 'blib/lib', 'blib/arch']
});

$harness->runtests([
    't/modules.t',
    't/auth.t'
]);
