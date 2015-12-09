#!/usr/bin/perl -w 

use v5.10;
use strict;
use ImgurAPI;
use Config::IniFiles;
use Data::Dumper;

# Read credentials from INI file
my $cfg = new Config::IniFiles(-file => 'auth.ini');

my $client_id       = $cfg->val('Credentials', 'client_id');
my $client_secret   = $cfg->val('Credentials', 'client_secret');
my $refresh_token   = $cfg->val('Credentials', 'refresh_token');
my $access_token    = $cfg->val('Credentials', 'access_token');
my $expiration_time = $cfg->val('Credentials', 'expiration_time');
my $authorized      = undef;

# Instantiate a ImgurAPI object
my $ImgurAPI   = new ImgurAPI($client_id, $client_secret, $refresh_token);

if(DateTime->now() >= $expiration_time) {
    if ($ImgurAPI->refresh() != 200) {
        say "Authentication refresh failed...";
        
        $authorized = $ImgurAPI->authorize();
    }
}

if($refresh_token ne $ImgurAPI->get_refresh_token() ||
   $access_token  ne $ImgurAPI->get_access_token()) {
    say "Updating auth.ini with new refresh_token...";

    $cfg->setval('Credentials', 'refresh_token',   $ImgurAPI->get_refresh_token());
    $cfg->setval('Credentials', 'access_token',    $ImgurAPI->get_access_token());
    $cfg->setval('Credentials', 'expiration_time', $ImgurAPI->get_expiration_datetime());
    
    # Save the new refresh_token, access_token, and expiration_time
    $cfg->RewriteConfig();
}

=pod
if(defined $expiration_time && length $expiration_time) {
    
}
else {

}
=cut

print Dumper($ImgurAPI->account('ANewBadlyPhotoshoppedPhotoofMichaelCeraEveryday'));
print Dumper($ImgurAPI);
