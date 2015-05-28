#!/usr/bin/perl -w

use v5.010;
use strict;
use Data::Dumper;
use Scalar::Util qw/reftype/;
use lib '/Users/Dillan/Development/Perl/ImgurAPI/lib/';
use Benchmark;
use ImgurAPI;

my $username = 'selftaught';
my $ImgurAPI = new ImgurAPI();
my $json = new JSON();

$ImgurAPI->auth_ini('/Users/Dillan/Development/Perl/ImgurAPI/examples/auth.ini');
#$ImgurAPI->set_format_type('xml');

#print Dumper($json->decode($ImgurAPI->get_album_images("FExBa")));
#print Dumper($json->decode($ImgurAPI->album_remove_images('FExBa', ('CkSUb3r'))));
#print Dumper($json->decode($ImgurAPI->post_comment_reply('oBGuvvI', '420948897', 'testing api')));
#print Dumper($json->decode($ImgurAPI->comment_vote('421144896', 'up')));
#print Dumper($json->decode($ImgurAPI->delete_image('qD2sCim')));
#print Dumper($json->decode($ImgurAPI->create_custom_gallery('awesome custom gallery', ('awesome', 'sauce'))));
#print Dumper($json->decode($ImgurAPI->get_notifications()));
#print Dumper($json->decode($ImgurAPI->get_notification('123093691')));
#print Dumper($json->decode($ImgurAPI->mark_notifications_as_read(('123093691'))));
#print Dumper($json->decode($ImgurAPI->gallery()));
#print Dumper($json->decode($ImgurAPI->memes_subgallery()));
#print Dumper($json->decode($ImgurAPI->subreddit_gallery('subreddit')));
#print Dumper($json->decode($ImgurAPI->gallery_tag('awesome')));
#print Dumper($json->decode($ImgurAPI->album_delete('q9bJ9')));

=pod
my $album_fields = {
	'title' => 'Wallpapers'
};

print Dumper($json->decode($ImgurAPI->album_create($album_fields)));
=cut

=pod
my $search_fields = {
	'q_any' => 'lol',
	'q_not' => 'boring'
};

print Dumper($json->decode($ImgurAPI->gallery_search('', $search_fields)));
=cut

=pod
my $image_url = 'http://thepaperwall.com/wallpapers/digital_artwork/big/big_b40813b197d643be752b98e9a94d576394c3638f.png';
my %image_fields = (
	'name' => 'Polygot wallpaper',
	'title' => 'Polygot Wallpaper',
	'album' => 'AbloT',
	'description' => 'Polygot wallpaper'
);

print Dumper($json->decode($ImgurAPI->upload_from_path('/Users/Dillan/Pictures/Wallpapers/abstract-digital-art-3D-CGI-minimalism-geometry-depth-of-field-simple-background.png', \%image_fields)));
#print Dumper($json->decode($ImgurAPI->upload_from_url($image_url, $image_fields)));
=cut

#--------------------
# Account methods
#--------------------

=pod
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
=cut

#--------------------
# Album methods
#--------------------


