
package ImgurAPI;

use strict;
use warnings;

use Data::Dumper;
use File::Slurp;
use HTTP::Request::Common;
use JSON qw(decode_json encode_json);
use List::Util qw(first);
use LWP::UserAgent;
use MIME::Base64;
use Mozilla::CA;
use Scalar::Util;
use XML::LibXML;


use constant ENDPOINTS => {
    'IMGUR'           => 'https://api.imgur.com/3',
    'RAPIDAPI'        => 'https://imgur-apiv3.p.rapidapi.com',
    'OAUTH_ADDCLIENT' => 'https://api.imgur.com/oauth2/addclient',
    'OAUTH_AUTHORIZE' => 'https://api.imgur.com/oauth2/authorize',
    'OAUTH_TOKEN'     => 'https://api.imgur.com/oauth2/token',
    'OAUTH_SECRET'    => 'https://api.imgur.com/oauth2/secret'
};

sub new {
    my $self = shift;
    my $args = shift // {};
    my $vars = {
        'auth'           => 1,
        'access_token'   => $args->{'access_token'},
        'oauth_cb_state' => $args->{'oauth_cb_state'},
        'client_id'      => $args->{'client_id'},
        'client_secret'  => $args->{'client_secret'},
        'format_type'    => $args->{'format_type'} // 'json',
        'rapidapi_key'   => $args->{'rapidapi_key'},
        'user_agent'     => LWP::UserAgent->new,
        'response'       => undef
        'ratelimit_hdrs' => {},
    };

    return bless $vars, $self;
}

sub _ua { shift->{'user_agent'} }

sub request {
    my ($self, $uri, $http_method, $data, $headers) = @_;

    $DB::single = 1;
    $http_method = $http_method ? uc $http_method : 'GET';

    my $end_point = (defined $self->{'rapidapi_key'} ? ENDPOINTS->{'RAPIDAPI'} . $uri : ENDPOINTS->{'IMGUR'} . $uri);

    $end_point  = ($uri =~ /^http(?:s)?/ ? $uri : $end_point);
    $end_point .= '?_format=' . $self->{'format_type'} . "&_method=$http_method";

    $self->_ua->default_header('User-Agent' => "ImgurAPI-perl-lib/0.1");

    if ($self->{'auth'}) {
        if (my $access_token = $self->{'access_token'}) {
            $self->_ua->default_header('Authorization' => "Bearer $access_token");
        } else { die "missing required access_token" }
    } elsif ($self->{'client_id'}) {
        $self->_ua->default_header('Authorization' => "Client-ID " . $self->{'client_id'});
    }

    if ($http_method =~ /^GET|DELETE$/ && scalar keys %$data) {
        while (my ($key, $value) = each %$data) {
            $end_point .= "&$key=$value";
        }
    }

    my $request;
    if ($http_method ne 'POST') {
        $request = HTTP::Request->new($http_method, $end_point);
    } else {
        $request = HTTP::Request::Common::POST($end_point, %{$headers // {}}, Content => $data);
    }

    my $api_resp = $self->_ua->request($request);
    my @ratelimit_headers = qw(userlimit userremaining userreset clientlimit clientremaining);

    foreach my $header (@ratelimit_headers) {
        $self->{'ratelimit_hdrs'}->{$header} = $api_resp->header("x-ratelimit-$header");
    }

    $self->{'response'} = $api_resp;
    $self->{'response_content'} = $api_resp->{'_content'};

    if ($self->format_type eq 'xml') {
        return (XML::LibXML->new)->load_xml(string => $api_resp->{'_content'});
    }

    my $decoded = eval { decode_json $api_resp->{'_content'} };

    if (my $err = $@) {
        die "failed to decode json response: $err\n";
    }

    return decode_json($api_resp->{'_content'});
}

# Setters
sub set_auth {
    my ($self, $auth) = @_;
    $self->{'auth'} = $auth;
}

sub set_client_id {
    my ($self, $client_id) = @_;
    $self->{'client_id'} = $client_id;
}

sub set_client_secret {
    my ($self, $client_secret) = @_;
    $self->{'client_secret'} = $client_secret;
}

sub set_format_type {
    my ($self, $format_type) = @_;
    $self->{'format_type'} = $format_type;
}

sub set_oauth_cb_state {
    my ($self, $oauth_cb_state) = @_;
    $self->{'oauth_cb_state'} = $oauth_cb_state;
}

sub set_access_token {
    my ($self, $access_token) = @_;
    $self->{'access_token'} = $access_token;
}

sub set_rapidapi_key {
    my ($self, $rapidapi_key) = @_;
    $self->{'rapidapi_key'} = $rapidapi_key;
}

# Getters
sub oauth2_authorize_url {
    my $self      = shift;
    my $client_id = $self->{'client_id'} or die "missing required client_id";
    my $state     = $self->{'oauth_cb_state'} // '';
    return (ENDPOINTS->{'OAUTH_AUTHORIZE'} . "?client_id=$client_id&response_type=token&state=$state");
}

sub client_id {
    return shift->{'client_id'};
}

sub client_secret {
    return shift->{'client_secret'}
}

sub access_token {
    return shift->{'access_token'}
}

sub format_type {
    return shift->{'format_type'}
}

sub oauth_cb_state {
    return shift->{'oauth_cb_state'}
}

sub rapidapi_key {
    return shift->{'rapidapi_key'}
}

sub response {
    return shift->{'response'}
}

sub response_content {
    return shift->{'response_content'}
}

sub ratelimit_headers {
    return shift->{'ratelimit_headers'}
}


sub _validate {
    my $self = shift;
}
# Account
sub account {
    my ($self, $user) = @_;
    return $self->request("/account/$user");
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

sub account_albums {
    my $self = shift;
    my $user = shift || 'me';
    my $page = shift || 1;
    return $self->request("/account/$user/albums/$page");
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
    my $body = shift or die "missing required post body\n";
    return $self->request("/account/me/delete?client_id=$client_id", 'POST', $body);
}

sub account_favorites {
    my $self = shift;
    my $user = shift // 'me';
    return $self->request("/account/$user/favorites");
}

sub account_gallery_favorites {
    my $self = shift;
    my $user = shift // 'me';
    my $page = shift || 1;
    my $sort = shift // 'newest';
    return $self->request("/account/$user/gallery_favorites/$page/$sort");
}

sub account_image {
    my $self = shift;
    my $user = shift // 'me';
    my $id   = shift or die "missing required image id\n";
    return $self->request("/account/$user/image/$id");
}

sub account_image_delete {
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

sub account_images {
    my $self = shift;
    my $user = shift // 'me';
    return $self->request("/account/$user/images");
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

sub account_submissions {
    my $self = shift;
    my $user = shift // 'me';
    my $page = shift || 1;
    return $self->request("/account/$user/submissions/$page");
}

# https://apidocs.imgur.com/#1f3f60f1-fc3f-4d06-b1c5-9bfc3610dacf
sub account_tag_follow {
    my $self = shift;
    my $tag  = shift or die "missing required tag\n";
    return $self->request("/account/me/follow/tag/$tag", 'POST');
}

# https://apidocs.imgur.com/#952bcee4-aab9-4679-9261-04845c59355e
sub account_tag_unfollow {
    my $self = shift;
    my $tag  = shift or die "missing required tag\n";
    return $self->request("/account/me/follow/tag/$tag", 'DELETE');
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

# Album
sub album {
    my ($self, $id) = @_;
    return $self->request("/album/$id");
}

# TODO: test this
sub album_create {
    my $self = shift;
    my $params = shift // {};
    my @optional_params = (qw(ids deletehashes title description privacy layout cover));
    my %valid_params = map { $_ => 1 } @optional_params;
    my $data = {};

    foreach my $param (keys %{$params}) {
        $data->{$param} = $params->{$param} unless ! exists($valid_params{$param});
    }

    return $self->request("/album", 'POST', $data);
}

sub album_delete {
    my ($self, $id) = @_;
    return $self->request("/album/$id", 'DELETE');
}

sub album_favorite {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    return $self->request("/album/$album_id/favorite", 'POST');
}

sub album_image {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    my $image_id = shift or die "missing required image id";
    return $self->request("/album/$album_id/image/$image_id");
}

sub album_images {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    return $self->request("/album/$album_id/images");
}

sub album_images_add {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $image_ids = shift or die "missing required image_ids";
    return $self->request("/album/$album_id/add", 'POST', $image_ids);
}

sub album_images_delete {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $image_ids = shift or die "missing required image_ids";
    return $self->request("/album/$album_id/remove_images", 'DELETE', {'ids' => join(',', @$image_ids)});
}

sub album_images_set {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $image_ids = shift or die "missing required image_ids";
    return $self->request("/album/$album_id", 'POST', $image_ids);
}

# TODO: test this
sub album_update {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $params = shift // {};
    my @optional_params = (qw(ids deletehashes title description privacy layout cover));
    my %valid_params = map { $_ => 1 } @optional_params;
    my $data = {};

    foreach my $param (keys %{$params}) {
        $data->{$param} = $params->{$param} unless ! exists($valid_params{$param});
    }

    return $self->request("/album/$album_id", 'PUT', $data);
}

# Comment
sub comment {
    my ($self, $id) = @_;
    return $self->request("/comment/$id");
}

# TODO: test this
sub comment_create {
    my $self = shift;
    my $image_id = shift or die "missing required image id";
    my $comment = shift or die "missing required comment";
    my $parent_id = shift;

    return $self->request("/comment", 'POST', {
        'image_id' => $image_id,
        'comment'  => $comment,
        ($parent_id ? ('parent_id'  => $parent_id) : ()),
    });
}

sub comment_delete {
    my $self = shift;
    my $image_id = shift or die "missing required image id";
    return $self->request("/comment/$image_id", 'DELETE');
}

sub comment_replies {
    my $self = shift;
    my $comment_id = shift or die "missing required comment_id";
    return $self->request("/comment/$comment_id/repies");
}

sub comment_reply {
    my $self = shift;
    my $image_id = shift or die "missing required image_id";
    my $comment_id = shift or die "missing required comment_id";
    my $comment = shift or die "missing required comment";

    my $data = {
        'image_id' => $image_id,
        'comment'  => $comment
    };

    $self->request("/comment/$comment_id", 'POST', $data);
}

# TODO: test this
sub comment_report {
    my $self = shift;
    my $comment_id = shift or die "missing required comment_id";
    my $reason = shift;
    my $data = {};

    if ($reason) {
        $data->{'reason'} = $reason;
    }

    return $self->request("/comment/$comment_id/report", 'POST', $data);
}

sub comment_vote {
    my $self = shift;
    my $comment_id = shift or die "missing required comment_id";
    my $vote = shift // 'up';

    return $self->request("/comment/$comment_id/vote/$vote", 'POST');
}

# Gallery
sub gallery {
    my $self = shift;
    my $optional = shift // {};

    die "optional data must be a hashref\n" if ref $optional ne 'HASH';

    my $section    = $optional->{'section'} // 'hot';
    my $sort       = $optional->{'sort'} // 'viral';
    my $page       = $optional->{'page'} // 0;
    my $window     = $optional->{'window'} // 'day';
    my $show_viral = $optional->{'show_viral'} // 1;
    my $album_prev = $optional->{'album_previews'} // 1;

    return $self->request(("/gallery/$section/$sort" . ($section eq 'top' ? "/$window" : "") . "/$page?showViral=$show_viral"));
}

sub gallery_album {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    return $self->request("/gallery/album/$album_id");
}

sub gallery_image {
    my $self = shift;
    my $image_id = shift or die "missing required image id";
    return $self->request("/gallery/image/$image_id");
}

sub gallery_item {
    my ($self, $id) = @_;
    return $self->request("/gallery/$id");
}

sub gallery_item_comment {
    my $self = shift;
    my $id = shift or die "missing required album/image id";
    my $comment = shift or die "missing required comment";
    return $self->request("/gallery/$id/comment", 'POST', {comment => $comment});
}

sub gallery_item_comment_info {
    my $self = shift;
    my $id = shift or die "missing required album/image id";
    my $comment_id = shift or die "missing required comment id";
    return $self->request("/gallery/$id/comment/$comment_id");
}

sub gallery_item_comments {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $optional = shift // {};
    my $sort = $optional->{'sort'} // 'best';
    return $self->request("/gallery/$id/comments/$sort");
}

sub gallery_item_report {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $optional = shift // {};
    my $reason = $optional->{'reason'};
    my %data = ($reason ? (reason => $reason) : ());

    $data{'reason'} = $reason if $reason;

    return $self->request("/gallery/image/$id/report", 'POST', \%data);
}

sub gallery_item_tags {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    return $self->request("/gallery/$id/tags");
}

sub gallery_item_tags_update {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $tags = shift or die "missing required tags";
    return $self->request("/gallery/$id/tags", 'POST', {'tags' => $tags});
}

sub gallery_item_vote {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $vote = shift or die "missing required vote";
    return $self->request("/gallery/$id/vote/$vote", 'POST');
}

sub gallery_item_votes {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    return $self->request("/gallery/$id/votes");
}

sub gallery_image_remove {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/gallery/$id", 'DELETE');
}

sub gallery_search {
    my $self = shift;
    my $query = shift;
    my $optional = shift // {};
    my $advanced = shift // {};
    my $sort = $optional->{'sort'} // 'time';
    my $window = $optional->{'window'} // 'all';
    my $page = $optional->{'page'} // 0;
    my $data = {};

    if ($advanced) {
        my %adv_keys = map { $_ => 1 } ('q_all', 'q_any', 'q_exactly', 'q_not', 'q_type', 'q_size_px');
        foreach my $key (keys %{$advanced}) {
            $data->{$key} = $advanced->{$key} unless ! exists($adv_keys{$key});
        }
    } elsif (!$query) {
        die "must provide a query or advanced search parameters";
    }

    return $self->request("/gallery/search/$sort/$window/$page" . ($advanced ? '' : "?q=$query"), 'GET', $data);
}

sub gallery_share_image {
    my $self = shift;
    my $image_id = shift or die "missing required image id";
    my $title = shift or die "missing required title";
    my $optional = shift // {};
    my $data = {'title' => $title};

    if ($optional) {
        my @optional_keys = ('topic', 'terms', 'mature', 'tags');
        foreach my $key (keys %{$optional}) {
            if (first { $_ eq $key } @optional_keys) {
                if ($key eq 'tags') {
                    if (ref $optional->{'tags'} eq 'ARRAY') {
                        $optional->{'tags'} = join(',', @{$optional->{'tags'}});
                    }
                }
                $data->{$key} = $optional->{$key};
            }
        }
    }

    return $self->request("/gallery/image/$image_id", "POST", $data);
}

sub gallery_share_album {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    my $title = shift or die "missing required title";
    my $optional = shift // {};
    my $data = {'title' => $title};

    if ($optional) {
        my @optional_keys = ('topic', 'terms', 'mature', 'tags');
        foreach my $key (keys %{$optional}) {
            if (first { $_ eq $key } @optional_keys) {
                if ($key eq 'tags') {
                    if (ref $optional->{'tags'} eq 'ARRAY') {
                        $optional->{'tags'} = join(',', @{$optional->{'tags'}});
                    }
                }
                $data->{$key} = $optional->{$key};
            }
        }
    }

    return $self->request("/gallery/album/$album_id", "POST", $data);
}

sub gallery_subreddit {
    my $self = shift;
    my $subreddit = shift or die "missing required subreddit";
    my $optional = shift // {};

    die "optional data must be a hashref\n" if ref $optional ne 'HASH';

    my $sort = $optional->{'sort'} // 'time';
    my $window = $optional->{'window'} // 'week';
    my $page = $optional->{'page'} // 0;

    return $self->request(("/gallery/r/$subreddit/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_subreddit_image {
    my $self = shift;
    my $subreddit = shift or die "missing required subreddit";
    my $image_id = shift or die "missing required image id";

    return $self->request("/gallery/r/$subreddit/$image_id");
}

sub gallery_tag {
    my $self = shift;
    my $tag = shift or die "missing required tag";
    my $optional = shift // {};
    my $sort = $optional->{'sort'} // 'viral';
    my $page = $optional->{'page'} // 0;
    my $window = $optional->{'window'} // 'week';

    return $self->request(("/gallery/t/$tag/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_tag_info {
    my $self = shift;
    my $tag = shift or die "missing required tag";
    return $self->request("/gallery/tag_info/$tag");
}

sub gallery_tag_vote {
    my ($self, $id, $tag, $vote) = @_;
    return $self->response("/gallery/$id/vote/tag/$tag/$vote", 'POST');
}

sub gallery_tags {
    my $self = shift;
    return $self->request("/tags");
}

# Image
sub image {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/image/$id");
}

sub image_upload {
    my $self = shift;
    my $src = shift or die "missing required image/video src";
    my $type = shift or die "missing required image/video type";
    my $optional = shift // {};
    my $data = {'image' => $src, 'type' => $type};
    my %headers = ();

    $data->{'title'} = $optional->{'title'} if $optional->{'title'};
    $data->{'description'} = $optional->{'description'} if $optional->{'description'};

    if ($type eq 'file') {
        die "file doesnt exist at path: $src\n" unless -e $src;
        die "provided src file path is not a file\n" unless -f $src;
        $data->{'image'} = [ $src ];
        $headers{Content_Type} = 'form-data';
    }

    return $self->request("/image", 'POST', $data, \%headers);
}

sub image_delete {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/image/$id", 'DELETE');
}

sub image_favorite {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/image/$id/favorite", 'POST');
}

sub image_update {
    my $self = shift;
    my $id = shift or die "missing required image id";
    my $optional = shift // {};
    return $self->request("/image/$id", 'POST', $optional);
}


# Feed
sub feed {
    my $self = shift;
    return $self->request("/feed");
}

1;
