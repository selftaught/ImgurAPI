#!/usr/bin/perl -w

use v5.010;
use strict;
use Data::Dumper;
use Scalar::Util qw/reftype/;
use lib '/Users/Dillan/Development/Perl/ImgurAPI/lib/';
use Benchmark;
use ImgurAPI::ImgurAPI;

my $username = 'selftaught';
my $ImgurAPI = new ImgurAPI();

$ImgurAPI->auth_ini('/Users/Dillan/Development/Perl/ImgurAPI/examples/auth.ini');
#$ImgurAPI->set_format_type('xml');

#--------------------
# Account methods
#--------------------


say "get_account:";
print Dumper($ImgurAPI->get_account($username));

say "\nget_gallery_favorites:";
print Dumper($ImgurAPI->get_gallery_favorites($username));

say "\nget_account_favorites:";
print Dumper($ImgurAPI->get_account_favorites($username));

say "\nget_account_comments:";
print Dumper($ImgurAPI->get_account_comments($username));

say "\nget_account_submissions:";
print Dumper($ImgurAPI->get_account_submissions($username));

say "\nget_account_settings:";
print Dumper($ImgurAPI->get_account_settings($username));

say "\nget_account_albums:";
print Dumper($ImgurAPI->get_account_albums($username));

say "\nget_account_album_ids:";
print Dumper($ImgurAPI->get_account_album_ids($username));

say "\nget_user_galleries:";
print Dumper($ImgurAPI->get_user_galleries());


#--------------------
# Album methods
#--------------------


