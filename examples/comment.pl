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


my $account_images = $client->account_images('me');
my $image_id = undef;
my $comment_id = undef;

if ($image_id = eval { $account_images->{'data'}->[0]->{'id'} }) {
    my $comment_create = $client->comment_create($image_id, 'This is a test comment');
    print Dumper $comment_create;
    $comment_id = $comment_create->{'data'}->{'id'};
=comment_create
{
    'success' => 1,
    'data' => {
        'id' => 2386727269
    },
    'status' => 200
}
=cut
}

if (defined $comment_id) {
    my $comment_info = $client->comment($comment_id);
    print Dumper $comment_info;
=comment
{
    'status' => 200,
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'data' => {
        'author_id' => 179790421,
        'has_admin_badge' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'parent_id' => 0,
        'points' => 1,
        'datetime' => 1711344066,
        'comment' => 'This is a test comment',
        'children' => [],
        'album_cover' => undef,
        'on_album' => $VAR1->{'data'}{'has_admin_badge'},
        'ups' => 1,
        'id' => 2386727561,
        'image_id' => 'DcYwgVi',
        'deleted' => $VAR1->{'data'}{'has_admin_badge'},
        'author' => 'SelfTaughtBot',
        'platform' => 'api',
        'downs' => 0,
        'vote' => 'up'
    }
}
=cut

    my $comment_reply = $client->comment_reply($image_id, $comment_id, 'This is a test reply');
    print Dumper $comment_reply;
=comment_reply
{
    'data' => {
        'id' => 2386730501
    },
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'status' => 200
}
=cut

    my $comment_replies = $client->comment_replies($comment_id);
    print Dumper $comment_replies;
=comment_replies
{
    'data' => {
        'vote' => 'up',
        'author_id' => 179790421,
        'datetime' => 1711346725,
        'children' => [
            {
            'parent_id' => 2386731189,
            'id' => 2386731193,
            'author' => 'SelfTaughtBot',
            'platform' => 'api',
            'points' => 1,
            'downs' => 0,
            'datetime' => 1711346726,
            'vote' => 'up',
            'author_id' => 179790421,
            'children' => [],
            'image_id' => 'DcYwgVi',
            'on_album' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
            'has_admin_badge' => $VAR2->{'data'}{'children'}[0]{'on_album'},
            'comment' => 'This is a test reply',
            'ups' => 1,
            'deleted' => $VAR2->{'data'}{'children'}[0]{'on_album'},
            'album_cover' => undef
            }
        ],
        'points' => 1,
        'platform' => 'api',
        'downs' => 0,
        'id' => 2386731189,
        'parent_id' => 0,
        'author' => 'SelfTaughtBot',
        'ups' => 1,
        'deleted' => $VAR2->{'data'}{'children'}[0]{'on_album'},
        'album_cover' => undef,
        'has_admin_badge' => $VAR2->{'data'}{'children'}[0]{'on_album'},
        'comment' => 'This is a test comment',
        'image_id' => 'DcYwgVi',
        'on_album' => $VAR2->{'data'}{'children'}[0]{'on_album'}
    },
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'status' => 200
}
=cut

    my $comment_vote = $client->comment_vote($comment_id, 'up');
    print Dumper $comment_vote;
=comment_vote
{
    'status' => 200,
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'data' => $VAR1->{'success'}
}
=cut

    my $comment_delete = $client->comment_delete($comment_id);
    print Dumper $comment_delete;
=comment_delete
{
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'status' => 200,
    'data' => $VAR1->{'success'}
}
=cut
}