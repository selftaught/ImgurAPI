#!/usr/bin/env perl 

use strict;
use warnings;
use lib 'lib';
use Deps;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'ImgurAPI',
	AUTHOR    => 'selftaught',
	VERSION   => '0.01',
	PREREQ_PM => {
        'JSON'                      => '2.90',
        'LWP::UserAgent'            => '6.05',
        'HTTP::Daemon'              => '6.01',
        'HTTP::Request::Common'     => '6.04',
        'Data::Dumper'              => '2.154',
        'DateTime::Format::ISO8601' => '0.08',
        'Config::IniFiles'          => '2.86',    
        'Scalar::Util'              => '1.42',
        'Class::Std::Utils'         => '0.0.3',
        'MIME::Base64'              => '3.15',
        'File::Slurp'               => '9999.19',
        'IO::File'                  => '1.16',
        'Template'                  => '2.26'
    } 
);
