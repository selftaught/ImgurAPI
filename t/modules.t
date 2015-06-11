#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 15;

BEGIN {
    use_ok('ImgurAPI');
    use_ok('ImgurAPI::MockupServer');
    use_ok('JSON');
    use_ok('LWP::UserAgent');
    use_ok('HTTP::Daemon');
    use_ok('HTTP::Request::Common');
    use_ok('Data::Dumper');
    use_ok('DateTime::Format::ISO8601');
    use_ok('Config::IniFiles');
    use_ok('Scalar::Util');
    use_ok('Class::Std::Utils');
    use_ok('MIME::Base64');
    use_ok('File::Slurp');
    use_ok('IO::File');
    use_ok('Template');
}
