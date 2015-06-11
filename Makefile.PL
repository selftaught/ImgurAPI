#!/usr/bin/env perl 

use strict;
use warnings;
use lib 'lib';
use Deps;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'ImgurAPI',
	AUTHOR    => 'Dillan Hildebrand',
	VERSION   => '0.01',
	PREREQ_PM => $deps
);
