#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use ImgurAPI::Client;

my $client = ImgurAPI::Client->new({
    client_id => $ENV{'CLIENT_ID'},
    client_secret => $ENV{'CLIENT_SECRET'},
    access_token => $ENV{'ACCESS_TOKEN'},
});


my $gallery = $client->gallery();
# print Dumper $gallery;

my $album_id = undef;
my $image_id = undef;

foreach my $item (@{$gallery->{'data'}}) {
    if ($item->{'is_album'}) {
        $album_id = $item->{'id'};
    }
}

=gallery
{
    'data' => [
        {
        'ad_config' => {
            'unsafe_flags' => [],
            'showAdLevel' => 2,
            'safeFlags' => [
                'album',
                'in_gallery',
                'gallery'
            ],
            'safe_flags' => [
                'album',
                'in_gallery',
                'gallery'
            ],
            'show_ad_level' => 2,
            'high_risk_flags' => [],
            'showsAds' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
            'wall_unsafe_flags' => [],
            'show_ads' => $VAR1->{'data'}[0]{'ad_config'}{'showsAds'},
            'nsfw_score' => 0,
            'wallUnsafeFlags' => [],
            'highRiskFlags' => [],
            'unsafeFlags' => []
        },
        'link' => 'https://imgur.com/a/2h3jEs0',
        'images_count' => 1,
        'is_ad' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'id' => '2h3jEs0',
        'title' => "So glad I\x{2019}m safe",
        'points' => 1546,
        'downs' => 6,
        'topic' => undef,
        'account_id' => 86895079,
        'ups' => 1552,
        'in_most_viral' => $VAR1->{'data'}[0]{'ad_config'}{'showsAds'},
        'in_gallery' => $VAR1->{'data'}[0]{'ad_config'}{'showsAds'},
        'tags' => [
            {
                'logo_destination_url' => undef,
                'description_annotations' => {},
                'following' => $VAR1->{'data'}[0]{'is_ad'},
                'display_name' => 'Funny',
                'background_is_animated' => $VAR1->{'data'}[0]{'is_ad'},
                'background_hash' => '9r1qCDq',
                'is_whitelisted' => $VAR1->{'data'}[0]{'is_ad'},
                'is_promoted' => $VAR1->{'data'}[0]{'is_ad'},
                'name' => 'funny',
                'followers' => 6780537,
                'thumbnail_is_animated' => $VAR1->{'data'}[0]{'is_ad'},
                'logo_hash' => undef,
                'accent' => '633875',
                'total_items' => 2554490,
                'description' => 'LOLs, ROFLs, LMAOs',
                'thumbnail_hash' => undef
            }
        ],
        'vote' => undef,
        'images' => [
            {
            'id' => 'dH9MeL3',
            'title' => undef,
            'width' => 1290,
            'has_sound' => $VAR1->{'data'}[0]{'is_ad'},
            'is_ad' => $VAR1->{'data'}[0]{'is_ad'},
            'link' => 'https://i.imgur.com/dH9MeL3.jpg',
            'height' => 1044,
            'bandwidth' => 3759937328,
            'description' => undef,
            'ups' => undef,
            'points' => undef,
            'downs' => undef,
            'account_id' => undef,
            'vote' => undef,
            'tags' => [],
            'in_most_viral' => $VAR1->{'data'}[0]{'is_ad'},
            'in_gallery' => $VAR1->{'data'}[0]{'is_ad'},
            'ad_type' => 0,
            'favorite' => $VAR1->{'data'}[0]{'is_ad'},
            'comment_count' => undef,
            'animated' => $VAR1->{'data'}[0]{'is_ad'},
            'views' => 26131,
            'nsfw' => undef,
            'favorite_count' => undef,
            'edited' => '0',
            'type' => 'image/jpeg',
            'ad_url' => '',
            'account_url' => undef,
            'datetime' => 1711486663,
            'score' => undef,
            'section' => undef,
            'size' => 143888
            }
        ],
        'cover_width' => 1290,
        'is_album' => $VAR1->{'data'}[0]{'ad_config'}{'showsAds'},
        'description' => undef,
        'favorite_count' => 159,
        'views' => 48726,
        'comment_count' => 148,
        'nsfw' => $VAR1->{'data'}[0]{'is_ad'},
        'include_album_ads' => $VAR1->{'data'}[0]{'is_ad'},
        'favorite' => $VAR1->{'data'}[0]{'is_ad'},
        'ad_type' => 0,
        'privacy' => 'hidden',
        'topic_id' => undef,
        'section' => '',
        'score' => 1570,
        'layout' => 'blog',
        'cover_height' => 1044,
        'cover' => 'dH9MeL3',
        'datetime' => 1711486669,
        'ad_url' => '',
        'account_url' => 'kidfromOKwiththetuckfromMB'
    },
    'success' => 1,
    'status' => 200
}
=cut

my $gallery_album = $client->gallery_album($album_id);
#print Dumper $gallery_album;

=gallery_album
    'data' => {
        'points' => 1577,
        'ad_url' => '',
        'topic' => undef,
        'vote' => undef,
        'ad_config' => {
            'wall_unsafe_flags' => [],
            'wallUnsafeFlags' => [],
            'show_ad_level' => 2,
            'high_risk_flags' => [],
            'show_ads' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
            'showAdLevel' => 2,
            'showsAds' => $VAR1->{'data'}{'ad_config'}{'show_ads'},
            'nsfw_score' => 0,
            'safe_flags' => [
                'album',
                'in_gallery',
                'gallery'
            ],
            'safeFlags' => [
                'album',
                'in_gallery',
                'gallery'
            ],
            'unsafeFlags' => [],
            'unsafe_flags' => [],
            'highRiskFlags' => []
        },
        'account_url' => 'kidfromOKwiththetuckfromMB',
        'in_gallery' => $VAR1->{'data'}{'ad_config'}{'show_ads'},
        'id' => '2h3jEs0',
        'cover_width' => 1290,
        'images_count' => 1,
        'include_album_ads' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'ups' => 1583,
        'description' => undef,
        'account_id' => 86895079,
        'score' => 1601,
        'tags' => [
            {
            'display_name' => 'Funny',
            'accent' => '633875',
            'logo_destination_url' => undef,
            'background_hash' => '9r1qCDq',
            'is_whitelisted' => $VAR1->{'data'}{'include_album_ads'},
            'thumbnail_hash' => undef,
            'logo_hash' => undef,
            'description_annotations' => {},
            'following' => $VAR1->{'data'}{'include_album_ads'},
            'total_items' => 2554490,
            'is_promoted' => $VAR1->{'data'}{'include_album_ads'},
            'name' => 'funny',
            'followers' => 6780538,
            'thumbnail_is_animated' => $VAR1->{'data'}{'include_album_ads'},
            'description' => 'LOLs, ROFLs, LMAOs',
            'background_is_animated' => $VAR1->{'data'}{'include_album_ads'}
            }
        ],
        'datetime' => 1711486669,
        'topic_id' => undef,
        'section' => '',
        'link' => 'https://imgur.com/a/2h3jEs0',
        'cover_height' => 1044,
        'layout' => 'blog',
        'downs' => 6,
        'in_most_viral' => $VAR1->{'data'}{'ad_config'}{'show_ads'},
        'is_album' => $VAR1->{'data'}{'ad_config'}{'show_ads'},
        'favorite' => $VAR1->{'data'}{'include_album_ads'},
        'privacy' => 'hidden',
        'comment_count' => 153,
        'is_ad' => $VAR1->{'data'}{'include_album_ads'},
        'images' => [
            {
                'ups' => undef,
                'description' => undef,
                'score' => undef,
                'account_id' => undef,
                'width' => 1290,
                'tags' => [],
                'datetime' => 1711486663,
                'points' => undef,
                'ad_url' => '',
                'bandwidth' => 3822384720,
                'vote' => undef,
                'account_url' => undef,
                'in_gallery' => $VAR1->{'data'}{'include_album_ads'},
                'id' => 'dH9MeL3',
                'favorite' => $VAR1->{'data'}{'include_album_ads'},
                'comment_count' => undef,
                'is_ad' => $VAR1->{'data'}{'include_album_ads'},
                'favorite_count' => undef,
                'edited' => '0',
                'height' => 1044,
                'title' => undef,
                'ad_type' => 0,
                'nsfw' => undef,
                'views' => 26565,
                'section' => undef,
                'type' => 'image/jpeg',
                'link' => 'https://i.imgur.com/dH9MeL3.jpg',
                'has_sound' => $VAR1->{'data'}{'include_album_ads'},
                'size' => 143888,
                'animated' => $VAR1->{'data'}{'include_album_ads'},
                'downs' => undef,
                'in_most_viral' => $VAR1->{'data'}{'include_album_ads'}
            }
        ],
        'favorite_count' => 161,
        'cover' => 'dH9MeL3',
        'title' => "So glad I\x{2019}m safe",
        'nsfw' => $VAR1->{'data'}{'include_album_ads'},
        'ad_type' => 0,
        'views' => 49634
    },
    'status' => 200,
    'success' => $VAR1->{'data'}{'ad_config'}{'show_ads'}
}
=cut

# my $gallery_image = $client->gallery_image($image_id);
# print Dumper $gallery_image;

=gallery_image
=cut


my $gallery_subreddit = $client->gallery_subreddit('programming');
# print Dumper $gallery_subreddit;

=gallery_subreddit
{
    'data' => [
        {
            'account_id' => undef,
            'favorite' => $VAR1->{'data'}[0]{'animated'},
            'title' => 'Never interrupt a programmer',
            'favorite_count' => undef,
            'tags' => [],
            'in_most_viral' => $VAR1->{'data'}[0]{'animated'},
            'type' => 'image/jpeg',
            'vote' => undef,
            'is_ad' => $VAR1->{'data'}[0]{'animated'},
            'views' => 175070,
            'points' => undef,
            'is_album' => $VAR1->{'data'}[0]{'animated'},
            'datetime' => 1392822963,
            'bandwidth' => '25397404900',
            'has_sound' => $VAR1->{'data'}[0]{'animated'},
            'ad_config' => {
                'wall_unsafe_flags' => [],
                'showAdLevel' => 2,
                'nsfw_score' => 0,
                'show_ad_level' => 2,
                'show_ads' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
                'unsafeFlags' => [],
                'wallUnsafeFlags' => [],
                'showsAds' => $VAR1->{'data'}[1]{'ad_config'}{'show_ads'},
                'safeFlags' => [
                    'in_gallery',
                    'subreddit'
                ],
                'highRiskFlags' => [],
                'safe_flags' => [
                    'in_gallery',
                    'subreddit'
                ],
                'high_risk_flags' => [],
                'unsafe_flags' => []
            },
            'ups' => undef,
            'nsfw' => $VAR1->{'data'}[0]{'animated'},
            'description' => undef,
            'score' => 154166,
            'link' => 'https://i.imgur.com/3uyRWGJ.jpg',
            'edited' => 0,
            'animated' => $VAR1->{'data'}[0]{'animated'},
            'in_gallery' => $VAR1->{'data'}[0]{'animated'},
            'downs' => undef,
            'height' => 2073,
            'ad_url' => '',
            'ad_type' => 0,
            'id' => '3uyRWGJ',
            'comment_count' => undef,
            'width' => 540,
            'account_url' => undef,
            'size' => 145070,
            'section' => 'programming'
        },
    ]
    'status' => 200,
    'success' => $VAR1->{'data'}[1]{'ad_config'}{'show_ads'}
}
=cut

my $subreddit_image_id = $gallery_subreddit->{'data'}->[0]->{'id'};
my $gallery_subreddit_image = $client->gallery_subreddit_image(
    'programming', $subreddit_image_id
);
# print Dumper $gallery_subreddit_image;

=gallery_subreddit_image
{
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'status' => 200,
    'data' => {
        'ups' => undef,
        'datetime' => 1399607763,
        'in_gallery' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'width' => 484,
        'is_album' => $VAR1->{'data'}{'in_gallery'},
        'views' => 2232,
        'link' => 'https://i.imgur.com/ccLYTtL.png',
        'size' => 164711,
        'section' => 'programming',
        'account_url' => undef,
        'in_most_viral' => $VAR1->{'data'}{'in_gallery'},
        'has_sound' => $VAR1->{'data'}{'in_gallery'},
        'bandwidth' => 367634952,
        'account_id' => undef,
        'nsfw' => $VAR1->{'data'}{'in_gallery'},
        'ad_url' => '',
        'score' => 51678,
        'description' => undef,
        'title' => 'Web development explained with butt analogies',
        'id' => 'ccLYTtL',
        'vote' => undef,
        'ad_config' => {
            'showsAds' => $VAR1->{'data'}{'in_gallery'},
            'safe_flags' => [
                'not_in_gallery',
                'subreddit'
            ],
            'nsfw_score' => '0.9',
            'wallUnsafeFlags' => [
                'onsfw_mod_unsafe_wall'
            ],
            'showAdLevel' => 0,
            'safeFlags' => [
                'not_in_gallery',
                'subreddit'
            ],
            'unsafeFlags' => [
                'onsfw_mod_unsafe'
            ],
            'highRiskFlags' => [],
            'unsafe_flags' => [
                'onsfw_mod_unsafe'
            ],
            'wall_unsafe_flags' => [
                'onsfw_mod_unsafe_wall'
            ],
            'high_risk_flags' => [],
            'show_ad_level' => 0,
            'show_ads' => $VAR1->{'data'}{'in_gallery'}
        },
        'is_ad' => $VAR1->{'data'}{'in_gallery'},
        'points' => undef,
        'favorite' => $VAR1->{'data'}{'in_gallery'},
        'ad_type' => 0,
        'animated' => $VAR1->{'data'}{'in_gallery'},
        'height' => 650,
        'edited' => 0,
        'tags' => [],
        'downs' => undef,
        'type' => 'image/png',
        'comment_count' => undef,
        'favorite_count' => undef
    }
}
=cut


my $gallery_tag = $client->gallery_tag('theoffice');
print Dumper $gallery_tag;

=gallery_tab
{
    'data' => {
        'display_name' => 'theoffice',
        'background_hash' => '5uFU9FR',
        'description' => '',
        'following' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'is_whitelisted' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
        'thumbnail_is_animated' => $VAR1->{'data'}{'following'},
        'background_is_animated' => $VAR1->{'data'}{'following'},
        'followers' => 3432,
        'logo_destination_url' => undef,
        'total_items' => 1893,
        'thumbnail_hash' => undef,
        'is_promoted' => $VAR1->{'data'}{'following'},
        'items' => [
            {
                'cover_height' => 445,
                'account_id' => 178806661,
                'description' => undef,
                'account_url' => 'TRFRADIO',
                'section' => '',
                'topic_id' => undef,
                'id' => '6YTszNe',
                'layout' => 'blog',
                'nsfw' => $VAR1->{'data'}{'following'},
                'score' => 9,
                'vote' => undef,
                'privacy' => 'hidden',
                'in_most_viral' => $VAR1->{'data'}{'following'},
                'favorite' => $VAR1->{'data'}{'following'},
                'views' => 1030,
                'favorite_count' => 0,
                'tags' => [
                    {
                    'total_items' => 8842,
                    'is_promoted' => $VAR1->{'data'}{'following'},
                    'thumbnail_hash' => undef,
                    'description_annotations' => {},
                    'logo_hash' => undef,
                    'name' => 'birthday',
                    'accent' => '2E6197',
                    'display_name' => 'birthday',
                    'background_hash' => 'eWY7qg5',
                    'description' => '',
                    'following' => $VAR1->{'data'}{'following'},
                    'is_whitelisted' => $VAR1->{'data'}{'following'},
                    'thumbnail_is_animated' => $VAR1->{'data'}{'following'},
                    'background_is_animated' => $VAR1->{'data'}{'following'},
                    'logo_destination_url' => undef,
                    'followers' => 2094
                    },
                    {
                    'background_hash' => 'R1dEESs',
                    'description' => '',
                    'display_name' => 'tantric',
                    'is_whitelisted' => $VAR1->{'data'}{'following'},
                    'background_is_animated' => $VAR1->{'data'}{'following'},
                    'thumbnail_is_animated' => $VAR1->{'data'}{'following'},
                    'logo_destination_url' => undef,
                    'followers' => 3,
                    'following' => $VAR1->{'data'}{'following'},
                    'thumbnail_hash' => undef,
                    'is_promoted' => $VAR1->{'data'}{'following'},
                    'total_items' => 2,
                    'logo_hash' => undef,
                    'accent' => '5E58CB',
                    'name' => 'tantric',
                    'description_annotations' => {}
                    },
                    {
                    'is_whitelisted' => $VAR1->{'data'}{'following'},
                    'background_is_animated' => $VAR1->{'data'}{'following'},
                    'thumbnail_is_animated' => $VAR1->{'data'}{'following'},
                    'logo_destination_url' => undef,
                    'followers' => 15,
                    'following' => $VAR1->{'data'}{'following'},
                    'background_hash' => '5uFU9FR',
                    'description' => '',
                    'display_name' => 'walkhard',
                    'logo_hash' => undef,
                    'accent' => 'B85E44',
                    'name' => 'walkhard',
                    'description_annotations' => {},
                    'thumbnail_hash' => undef,
                    'is_promoted' => $VAR1->{'data'}{'following'},
                    'total_items' => 19
                    },
                    {
                    'accent' => 'B85E44',
                    'name' => 'theoffice',
                    'logo_hash' => undef,
                    'description_annotations' => {},
                    'thumbnail_hash' => undef,
                    'is_promoted' => $VAR1->{'data'}{'following'},
                    'total_items' => 1891,
                    'logo_destination_url' => undef,
                    'followers' => 3432,
                    'is_whitelisted' => $VAR1->{'data'}{'following'},
                    'background_is_animated' => $VAR1->{'data'}{'following'},
                    'thumbnail_is_animated' => $VAR1->{'data'}{'following'},
                    'following' => $VAR1->{'data'}{'following'},
                    'description' => '',
                    'background_hash' => '5uFU9FR',
                    'display_name' => 'theoffice'
                    },
                    {
                    'display_name' => 'game of thrones',
                    'background_hash' => 'jFCTPdP',
                    'description' => 'spoilers within',
                    'following' => $VAR1->{'data'}{'following'},
                    'background_is_animated' => $VAR1->{'data'}{'following'},
                    'thumbnail_is_animated' => $VAR1->{'data'}{'following'},
                    'is_whitelisted' => $VAR1->{'data'}{'following'},
                    'followers' => 35748,
                    'logo_destination_url' => undef,
                    'total_items' => 23804,
                    'thumbnail_hash' => undef,
                    'is_promoted' => $VAR1->{'data'}{'following'},
                    'description_annotations' => {},
                    'logo_hash' => undef,
                    'name' => 'game_of_thrones',
                    'accent' => 'a18060'
                    }
                ],
                'include_album_ads' => $VAR1->{'data'}{'following'},
                'ad_url' => '',
                'ad_config' => {
                    'safe_flags' => [
                                    'album',
                                    'in_gallery',
                                    'gallery'
                                    ],
                    'unsafeFlags' => [],
                    'show_ad_level' => 2,
                    'wall_unsafe_flags' => [],
                    'highRiskFlags' => [],
                    'showAdLevel' => 2,
                    'show_ads' => $VAR1->{'data'}{'is_whitelisted'},
                    'safeFlags' => [
                                    'album',
                                    'in_gallery',
                                    'gallery'
                                    ],
                    'wallUnsafeFlags' => [],
                    'unsafe_flags' => [],
                    'nsfw_score' => '0.1',
                    'showsAds' => $VAR1->{'data'}{'is_whitelisted'},
                    'high_risk_flags' => []
                },
                'images' => [
                    {
                        'ups' => undef,
                        'has_sound' => $VAR1->{'data'}{'following'},
                        'ad_type' => 0,
                        'edited' => '0',
                        'in_gallery' => $VAR1->{'data'}{'following'},
                        'is_ad' => $VAR1->{'data'}{'following'},
                        'title' => undef,
                        'link' => 'https://i.imgur.com/o2MkiGB.png',
                        'height' => 445,
                        'datetime' => 1709825003,
                        'comment_count' => undef,
                        'downs' => undef,
                        'bandwidth' => 331739158,
                        'points' => undef,
                        'animated' => $VAR1->{'data'}{'following'},
                        'id' => 'o2MkiGB',
                        'size' => 475271,
                        'section' => undef,
                        'description' => undef,
                        'account_url' => undef,
                        'width' => 1200,
                        'account_id' => undef,
                        'ad_url' => '',
                        'type' => 'image/png',
                        'tags' => [],
                        'favorite_count' => undef,
                        'in_most_viral' => $VAR1->{'data'}{'following'},
                        'favorite' => $VAR1->{'data'}{'following'},
                        'views' => 698,
                        'score' => undef,
                        'vote' => undef,
                        'nsfw' => undef
                    }
                    ],
                'title' => 'Mar 7 birthdays',
                'is_ad' => $VAR1->{'data'}{'following'},
                'in_gallery' => $VAR1->{'data'}{'is_whitelisted'},
                'ad_type' => 0,
                'images_count' => 1,
                'ups' => 13,
                'cover' => 'o2MkiGB',
                'topic' => undef,
                'points' => 9,
                'downs' => 4,
                'comment_count' => 1,
                'is_album' => $VAR1->{'data'}{'is_whitelisted'},
                'datetime' => 1709825120,
                'link' => 'https://imgur.com/a/6YTszNe',
                'cover_width' => 1200
            },
        ],
        'description_annotations' => {},
        'logo_hash' => undef,
        'accent' => 'B85E44',
        'name' => 'theoffice'
    },
    'status' => 200,
    'success' => $VAR1->{'data'}{'is_whitelisted'}
}
=cut