
package ImgurAPI;

use strict;
use warnings;

use Data::Dumper;
use File::Slurp;
use HTTP::Request::Common;
use JSON qw(decode_json);
use LWP::UserAgent;
use MIME::Base64;
use Mozilla::CA;
use Scalar::Util;
use XML::LibXML;


use constant ENDPOINTS => {
    'IMGUR'          => 'https://api.imgur.com/3',
    'RAPIDAPI'         => 'https://imgur-apiv3.p.rapidapi.com',
    'OAUTH_ADDCLIENT' => 'https://api.imgur.com/oauth2/addclient',
    'OAUTH_AUTHORIZE' => 'https://api.imgur.com/oauth2/authorize',
    'OAUTH_TOKEN'     => 'https://api.imgur.com/oauth2/token',
    'OAUTH_SECRET'    => 'https://api.imgur.com/oauth2/secret'
};

sub new {
    my $self = shift;
    my $args = shift // {};
    my $vars = {
        'auth'          => 1,
        'access_token'  => $args->{'access_token'},
        'oauth_state'   => $args->{'oauth_state'} // '',
        'client_id'     => $args->{'client_id'},
        'client_secret' => $args->{'client_secret'},
        'format_type'   => $args->{'format_type'} // 'json',
        'mashape_key'   => $args->{'mashape_key'},
        'user_agent'    => LWP::UserAgent->new,
        'response'      => undef
    };

    return bless $vars, $self;
}

sub _ua { shift->{'user_agent'} }

sub request {
    my ($self, $uri, $http_method, $post_data) = @_;

    $http_method = $http_method ? uc $http_method : 'GET';

    my $end_point = (defined $self->{'mashape_key'} ? ENDPOINTS->{'RAPIDAPI'} . $uri : ENDPOINTS->{'IMGUR'} . $uri);

    $end_point  = ($uri =~ /^http(?:s)?/ ? $uri : $end_point);
    $end_point .= '?_format=' . ($self->{'format_type'} eq 'xml' ? 'xml' : 'json');
    $end_point .= "&_method=$http_method";

    if ($self->{'auth'}) {
        if (my $access_token = $self->{'access_token'}) {
            $self->_ua->default_header('Authorization' => "Bearer $access_token");
        } else { die "missing required access_token" }
    } elsif ($self->{'client_id'}) {
        $self->_ua->default_header('Authorization' => "Client-ID " . $self->{'client_id'});
    }

    if ($http_method =~ /^GET|DELETE$/ && scalar keys %$post_data) {
        while(my ($key, $value) = each %$post_data) {
            $end_point .= "&$key=$value";
        }
    }

    my $request = new HTTP::Request($http_method, $end_point, ($http_method eq 'POST' ? $post_data : undef));
    my $api_resp = $self->_ua->request($request);

    $self->{'x_ratelimit_userlimit'}      = $api_resp->{'_headers'}{'x-ratelimit-userlimit'};
    $self->{'x_ratelimit_userremaining'}  = $api_resp->{'_headers'}{'x-ratelimit-userremaining'};
    $self->{'x_ratelimit_userreset'}      = $api_resp->{'_headers'}{'x-ratelimit-userreset'};
    $self->{'x_ratelimit_clientlimit'}    = $api_resp->{'_headers'}{'x-ratelimit-clientlimit'};
    $self->{'x_ratelimit_lientremaining'} = $api_resp->{'_headers'}{'x-ratelimit-clientremaining'};

    $self->{'response'} = $api_resp;
    $self->{'response_content'} = $api_resp->{'_content'};

    if ($self->get_format_type eq 'xml') {
        return (XML::LibXML->new)->load_xml( string => $api_resp->{'_content'} );
    }

    # print Dumper $api_resp;

    return decode_json($api_resp->{'_content'});
}

# Setters
sub set_client_id    { shift->{'client_id'}    = shift }
sub set_format_type  { shift->{'format_type'}  = shift }
sub set_state        { shift->{'state'}        = shift }
sub set_access_token { shift->{'access_token'} = shift }
sub set_no_auth      { shift->{'auth'}         = 0     }

# Getters
sub get_oauth2_url {
    my $self      = shift;
    my $client_id = $self->{'client_id'};
    my $state     = $self->{'state'};
    return (ENDPOINTS->{'OAUTH_AUTHORIZE'} . "?client_id=$client_id&response_type=token&state=$state");
}

sub get_access_token                { return shift->{'access_token'}                }
sub get_format_type                 { return shift->{'format_type'}                 }
sub get_response                    { return shift->{'response'}                    }
sub get_response_content            { return shift->{'response_content'}            }
sub get_x_ratelimit_userlimit       { return shift->{'x_ratelimit_userlimit'}       }
sub get_x_ratelimit_userremaining   { return shift->{'x_ratelimit_userremaining'}   }
sub get_x_ratelimit_userreset       { return shift->{'x_ratelimit_userreset'}       }
sub get_x_ratelimit_clientlimit     { return shift->{'x_ratelimit_clientlimit'}     }
sub get_x_ratelimit_clientremaining { return shift->{'x_ratelimit_clientremaining'} }

# Account
sub account {
    my ($self, $user) = @_;
    return $self->request("/account/$user");
}

sub account_block_status {
    my ($self, $user) = @_;
    return $self->request("/account/$user/block");
}

sub account_blocks {
    my $self = shift;
    return $self->request("/account/me/block");
}

sub account_block_create {
    my ($self, $user) = @_;
    return $self->request("/account/v1/$user/block", 'POST');
}

sub account_block_delete {
    my ($self, $user) = @_;
    return $self->request("/account/v1/$user/block", 'DELETE');
}

# https://apidocs.imgur.com/#dcdbad18-260a-4501-8618-a26e7ccb8596
sub account_delete {
    my $self = shift;
    my $client_id = shift or die "missing required client id\n";
    my $body = shift or die "missing required post body\n"
    return $self->request("/account/me/delete?client_id=$client_id", 'POST');
}

# https://apidocs.imgur.com/#1f3f60f1-fc3f-4d06-b1c5-9bfc3610dacf
sub account_follow_tag {
    my $self = shift;
    my $tag  = shift or die "missing required tag\n";
    return $self->request("/account/me/follow/tag/$tag", 'POST');
}

# https://apidocs.imgur.com/#952bcee4-aab9-4679-9261-04845c59355e
sub account_unfollow_tag {
    my $self = shift;
    my $tag  = shift or die "missing required tag\n";
    return $self->request("/account/me/follow/tag/$tag", 'DELETE');
}

sub account_images {
    my $self = shift;
    my $user = shift // 'me';
    return $self->request("/account/$user/images");
}

sub account_image {
    my $self = shift;
    my $user = shift // 'me';
    my $id   = shift or die "missing required image id\n";
    return $self->request("/account/$user/image/$id");
}

sub account_iamge_delete {
    my $self = shift;
    my $user = shift // 'me';
    my $id   = shift or die "missing required image delete has\n";
    return $self->request("/account/$user/image/$id", 'DELETE');
}

sub account_image_ids {
    my $self = shift;
    my $user = shift // 'me';
    my $page = shift || 1;
    return $self->request("/account/$user/image/ids/$page");
}

sub account_gallery_favorites {
    my $self = shift;
    my $user = shift // 'me';
    my $page = shift || 1;
    my $sort = shift // 'newest';
    return $self->request("/account/$user/gallery_favorites/$page/$sort");
}

sub account_favorites {
    my $self = shift;
    my $user = shift // 'me';
    return $self->request("/account/$user/favorites");
}

sub account_submissions {
    my $self = shift;
    my $user = shift // 'me';
    my $page = shift || 1;
    return $self->request("/account/$user/submissions/$page");
}

sub account_verify_email_send {
    my $self = shift;
    my $user = shift // 'me';
    return $self->request("/account/$user/verifyemail", 'POST');
}

sub account_verify_email_status {
    my $self = shift;
    my $user = shift // 'me';
    return $self->request("/account/$user/verifyemail");
}

sub account_albums {
    my $self = shift;
    my $user = shift || 'me';
    my $page = shift || 1;
    return $self->request("/account/$user/albums/$page");
}

sub account_album {
    my $self = shift;
    my $user = shift || 'me';
    my $hash = shift or die "missing required album hash\n";
    return $self->request("/account/$user/album/$hash");
}

sub account_album_ids {
    my $self = shift;
    my $user = shift || 'me';
    my $page = shift || 1;
    return $self->request("/account/$user/ids/$page");
}

sub account_album_count {
    my $self = shift;
    my $user = shift || 'me';
    return $self->request("/account/$user/albums/count");
}

sub account_album_delete {
    my $self = shift;
    my $user = shift || 'me';
    my $hash = shift or die "missing required album hash\n";
    return $self->request("/account/$user/album/$hash", 'DELETE');
}

sub account_comments {
    my $self = shift;
    my $user = shift || 'me';
    my $sort = shift // 'newest';
    my $page = shift || 1;
    return $self->request("/account/$user/comments/$sort/$page");
}

sub account_comment {
    my $self = shift;
    my $user = shift || 'me';
    my $id   = shift or die "missing required comment id\n";
    return $self->request("/account/$user/comment/$id");
}

sub account_comment_ids {
    my $self = shift;
    my $user = shift || 'me';
    my $sort = shift // 'newest';
    my $page = shift || 1;
    return $self->request("/account/$user/comments/ids/$sort/$page");
}

sub account_comment_count {
    my $self = shift;
    my $user = shift || 'me';
    return $self->request("/account/$user/comments/count");
}

sub account_comment_delete {
    my $self = shift;
    my $user = shift || 'me';
    my $id   = shift or die "missing required comment id\n";
    return $self->request("/account/$user/comment/$id", 'DELETE');
}

sub account_reply_notifications {
    my $self = shift;
    my $user = shift || 'me';
    my $new  = shift // 1;
    return $self->request("/account/$user/notifications/replies");
}

sub account_settings {
    my ($self, $user) = @_;
    return $self->request("/account/$user/settings");
}

sub account_settings_update {
    my ($self, $user, $settings) = @_;
    my %valid_setting_fields = map { $_ => 1 } ('bio', 'public_images', 'messaging_enabled', 'album_privacy', 'accepted_gallery_terms', 'username');
    my $data = {};

    die("Error: you must provide a hashref to the new account settings\n") unless $settings;

    foreach my $key (keys %{ $settings }) {
        $data->{ $key } = $settings->{ $key } unless ! exists($valid_setting_fields{ $key });
    }

    return $self->request("/account/$user/settings", 'POST', $data);
}

# Album
sub album {
    my ($self, $id) = @_;
    return $self->request("/album/$id");
}

sub album_images {
    my ($self, $id) = @_;
    return $self->request("/album/$id/images");
}

sub album_create {
    my ($self, $fields) = @_;
    my %valid_album_keys = map { $_ => 1 } ('ids', 'title', 'description', 'privacy', 'layout', 'cover');
    my $data = {};

    die("Error: you must provide fields when creating an album\n") unless $fields;

    foreach my $key (keys %{ $fields }) {
        $data->{ $key } = $fields->{ $key } unless ! exists($valid_album_keys{ $key });
    }

    return $self->request("/album", 'POST', $data);
}

sub album_update {
    my ($self, $id) = @_;
}

sub album_delete {
    my ($self, $id) = @_;
    return $self->request("/album/$id", 'DELETE');
}

sub album_favorite {
    my ($self, $id) = @_;
    return $self->request("/album/$id/favorite", 'POST');
}

sub album_set_images {
    my ($self, $id, $image_ids) = @_;
    return $self->request("/album/$id/", 'POST', $image_ids);
}

sub album_add_images {
    my ($self, $id, $image_ids) = @_;
    return $self->request("/album/$id/add", 'POST', $image_ids);
}

sub album_delete_images {
    my ($self, $id, @image_ids) = @_;
    return $self->request("/album/$id/remove_images", 'DELETE', {'ids' => join(',', @image_ids)});
}

# Comment
sub comment {
    my ($self, $id) = @_;
    return $self->request("/comment/$id");
}

sub comment_delete {
    my ($self, $id) = @_;
    return $self->request("/comment/$id", 'DELETE');
}

sub comment_replies {
    my ($self, $id) = @_;
    return $self->request("/comment/$id/repies");
}

sub comment_reply {
    my ($self, $image_id, $comment_id, $comment) = @_;
    my $data = {
        'image_id'   => $image_id,
        'comment_id' => $comment_id,
        'comment'    => $comment
    };

    $self->request("/comment/$comment_id", 'POST', $data);
}

sub comment_vote {
    my ($self, $id, $vote) = @_;
    $vote ||= 'up';
    return $self->request("/comment/$id/vote/$vote", 'POST');
}

sub comment_report {
    my ($self, $id) = @_;
    return $self->request("/comment/$id/report", 'POST');
}

# Gallery
sub gallery {
    my ($self, $section, $sort, $page, $window, $show_viral) = @_;
    $section    ||= 'hot';
    $sort       ||= 'viral';
    $page       ||= 0;
    $window     ||= 'day';
    $show_viral ||= 1;
    return $self->request(("/gallery/$section/$sort" . ($section eq 'top' ? "/$window" : "") . "/$page?showViral=$show_viral"));
}

sub gallery_subreddit {
    my ($self, $subreddit, $sort, $window, $page) = @_;
    $sort   ||= 'time';
    $window ||= 'week';
    $page   ||= 0;
    return $self->request(("/gallery/r/$subreddit/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_subreddit_image {
    my ($self, $subreddit, $id) = @_;
    return $self->request("/gallery/r/$subreddit/$id");
}

sub gallery_tag {
    my ($self, $tag, $sort, $page, $window) = @_;
    $sort   ||= 'viral';
    $page   ||= 0;
    $window ||= 'week';
    return $self->request(("/gallery/t/$tag/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_tag_image {
    my ($self, $tag, $id) = @_;
    return $self->request("/gallery/t/$tag/$id");
}

sub gallery_item_tags {
    my ($self, $id) = @_;
    return $self->request("/gallery/$id/tags");
}

sub gallery_tag_vote {
    my ($self, $id, $tag, $vote) = @_;
    return $self->response("/gallery/$id/vote/tag/$tag/$vote", 'POST');
}

sub gallery_search {
    my ($self, $query, $fields, $sort, $window, $page) = @_;
    $fields ||= {};
    $sort   ||= 'time';
    $window ||= 'all';
    $page   ||= 0;

    my $data = {};

    if ($fields) {
        my %valid_search_keys = map { $_ => 1 } ('q_all', 'q_any', 'q_exactly', 'q_not', 'q_type', 'q_size_px');

        foreach my $key (keys %{ $fields }) {
            $data->{ $key } = $fields->{ $key } unless ! exists($valid_search_keys{ $key });
        }
    }
    else {
        $data->{'q'} = $query;
    }

    return $self->request("/gallery/search/$sort/$window/$page", 'GET', $data);
}

sub gallery_random {
    my ($self, $page) = @_;
    return $self->request("/gallery/random/random/$page");
}

sub gallery_share_image {
    # TODO
}

sub gallery_share_album {
    # TODO
}

sub gallery_remove {
    my ($self, $id) = @_;
    return $self->request("/gallery/$id", 'DELETE');
}

sub gallery_item {
    my ($self, $id) = @_;
    return $self->request("/gallery/$id");
}

sub gallery_item_vote {
    my ($self, $id, $vote) = @_;
    $vote ||= 'up';
    return $self->request("/gallery/$id/vote/$vote", 'POST');
}

sub gallery_item_comments {
    my ($self, $id, $sort) = @_;
    $sort ||= 'best';
    return $self->request("/gallery/$id/comments/$sort");
}

sub gallery_comment {
    my ($self, $id, $comment) = @_;
    return $self->request("/gallery/$id/comment", 'POST', { 'comment' => $comment });
}

sub gallery_comment_ids {
    my ($self, $id) = @_;
    return $self->request("/gallery/$id/comments/ids");
}

sub gallery_comment_count {
    my ($self, $id) = @_;
    return $self->request("/gallery/$id/comments/count");
}

# Image
sub image {
    my ($self, $id) = @_;
    return $self->request("/image/$id");
}

sub image_upload_from_path {
    my ($self, $path, $fields, $anon) = @_;
    $fields ||= {};
    $anon   ||= 0;

    my $image_data = read_file($path);
    my $data       = {
        'image' => encode_base64($image_data),
        'type'  => 'base64'
    };

    if ($fields) {
        my %valid_image_keys = map { $_ => 1 } ('album', 'name', 'title', 'description');

        foreach my $key (keys %{ $fields }) {
            $data->{ $key } = $fields->{ $key } unless ! exists($valid_image_keys{ $key });
        }
    }

    return $self->request("/upload", 'POST', $data);
}

sub image_upload_from_url {
    my ($self, $url, $fields, $anon) = @_;

    $fields ||= {};
    $anon   ||= 0;

    my $data = {
        'image' => $url,
        'type'  => 'url'
    };

    if ($fields) {
        my %valid_image_keys = map { $_ => 1 } ('album', 'name', 'title', 'description');

        foreach my $key (keys %{ $fields }) {
            $data->{ $key } = $fields->{ $key } unless ! exists($valid_image_keys{ $key });
        }
    }

    return $self->request("/upload", 'POST', $data);
}

sub image_delete {
    my ($self, $id) = @_;
    return $self->request("/image/$id", 'DELETE');
}

sub image_favorite {
    my ($self, $id) = @_;
    return $self->request("/image/$id/favorite", 'POST');
}

# Feed
sub feed {
    my $self = shift;
    return $self->request("/feed");
}

1;
