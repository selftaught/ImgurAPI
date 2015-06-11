#!/usr/bin/env perl

package Deps;

use strict;
use warnings;

use Exporter;
our @ISA    = 'Exporter';
our @EXPORT = qw($deps);
our $deps   = {
    'JSON'                      => '2.90',
    'LWP::UserAgent'            => '6.05',
    'HTTP::Request::Common'     => '6.04',
    'Data::Dumper'              => '2.154',
    'DateTime::Format::ISO8601' => '0.08',
    'Config::IniFiles'          => '2.86',    
    'Scalar::Util'              => '1.42',
    'Class::Std::Utils'         => '0.0.3',
    'MIME::Base64'              => '3.15',
    'File::Slurp'               => '9999.19'
};

1;
