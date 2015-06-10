#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('ImgurAPI');
    use_ok('JSON');
    use_ok('LWP::UserAgent');
    use_ok('HTTP::Request::Common');
    use_ok('Data::Dumper');
    use_ok('DateTime::Format::ISO8601');
    use_ok('Config::IniFiles');
    use_ok('Scalar::Util');
    use_ok('Class::Std::Utils');
    use_ok('MIME::Base64');
    use_ok('File::Slurp');
    use_ok('HTTP::Daemon');
}
