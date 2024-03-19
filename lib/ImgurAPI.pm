
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
    'OAUTH_AUTHORIZE' => 'https://api.imgur.com/oauth2/authorize',
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
        'response'       => undef,
        'ratelimit_hdrs' => {},
    };

    return bless $vars, $self;
}

sub _ua { shift->{'user_agent'} }

sub request {
    my ($self, $uri, $http_method, $data, $headers) = @_;

    $http_method = $http_method ? uc $http_method : 'GET';

    my $end_point = (defined $self->{'rapidapi_key'} ? ENDPOINTS->{'RAPIDAPI'} . $uri : ENDPOINTS->{'IMGUR'} . $uri);

    $end_point  = ($uri =~ /^http(?:s)?/ ? $uri : $end_point);
    $end_point .= '?_format=' . $self->{'format_type'} . "&_method=$http_method";

    $self->_ua->default_header('User-Agent' => "ImgurAPI-perl-lib/0.1");

    if ($self->{'auth'}) {
        if (my $access_token = $self->{'access_token'}) {
            $self->_ua->default_header('Authorization' => "Bearer $access_token");
        } else {
            die "missing required access_token";
        }
    } elsif ($self->{'client_id'}) {
        $self->_ua->default_header('Authorization' => "Client-ID " . $self->{'client_id'});
    }

    if ($http_method =~ /^GET|DELETE$/ && scalar keys %$data) {
        while (my ($key, $value) = each %$data) {
            $end_point .= "&$key=$value";
        }
    }

    my $request;
    if ($http_method eq 'POST') {
        $request = HTTP::Request::Common::POST($end_point, %{$headers // {}}, Content => $data);
    } elsif ($http_method eq 'PUT') {
        $request = HTTP::Request::Common::PUT($end_point, %{$headers // {}}, Content => $data);
    } else {
        $request = HTTP::Request->new($http_method, $end_point);
    }

    print Dumper $request if $ENV{'DEBUG'};

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
        die "failed to decode json response: $err";
    }

    return $decoded;
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

# Account
sub account {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user");
}

sub account_album {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id   = shift or die "missing required album id";
    return $self->request("/account/$user/album/$id");
}

sub account_album_count {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/albums/count");
}

sub account_album_delete {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id   = shift or die "missing required album id";
    return $self->request("/account/$user/album/$id", 'DELETE');
}

sub account_album_ids {
    my $self = shift;
    my $user = shift or die "missing requied username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/ids/$page");
}

sub account_albums {
    my $self = shift;
    my $user = shift or die "missing requied username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/albums/$page");
}

sub account_block_status {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/block");
}

sub account_block_create {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/v1/$user/block", 'POST');
}

sub account_block_delete {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/v1/$user/block", 'DELETE');
}

sub account_blocks {
    my $self = shift;
    return $self->request("/account/me/block");
}

sub account_comment {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id   = shift or die "missing required comment id";
    return $self->request("/account/$user/comment/$id");
}

sub account_comment_count {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/comments/count");
}

sub account_comment_delete {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id   = shift or die "missing required comment id";
    return $self->request("/account/$user/comment/$id", 'DELETE');
}

sub account_comment_ids {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'newest';
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/comments/ids/$sort/$page");
}

sub account_comments {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'newest';
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/comments/$sort/$page");
}

# https://apidocs.imgur.com/#dcdbad18-260a-4501-8618-a26e7ccb8596
sub account_delete {
    my $self = shift;
    my $client_id = shift or die "missing required client id";
    my $body = shift or die "missing required post body";
    return $self->request("/account/me/delete?client_id=$client_id", 'POST', $body);
}

sub account_favorites {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'newest';
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/favorites/$page/$sort");
}

sub account_gallery_favorites {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'newest';
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/gallery_favorites/$page/$sort");
}

sub account_image {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id   = shift or die "missing required image id";
    return $self->request("/account/$user/image/$id");
}

sub account_image_count {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/images/count");
}

sub account_image_delete {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id   = shift or die "missing required image id";
    return $self->request("/account/$user/image/$id", 'DELETE');
}

sub account_image_ids {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/image/ids/$page");
}

sub account_images {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/images/$page");
}

sub account_reply_notifications {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $new  = $opts->{'new'} // 1;
    return $self->request("/account/$user/notifications/replies?new=$new");
}

sub account_settings {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/settings");
}

sub account_settings_update {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $settings = shift // {};
    my @valid_settings = (qw(bio public_images messaging_enabled accepted_gallery_terms username show_mature newsletter_subscribed));
    my %valid_settings_map = map { $_ => 1 } @valid_settings;
    my $data = {};

    foreach my $key (keys %{$settings}) {
        $data->{$key} = $settings->{$key} if exists $valid_settings_map{$key};
    }

    return $self->request("/account/$user/settings", 'PUT', $data);
}

sub account_submissions {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/submissions/$page");
}

sub account_tag_follow {
    my $self = shift;
    my $tag  = shift or die "missing required tag";
    return $self->request("/account/me/follow/tag/$tag", 'POST');
}

sub account_tag_unfollow {
    my $self = shift;
    my $tag  = shift or die "missing required tag";
    return $self->request("/account/me/follow/tag/$tag", 'DELETE');
}

sub account_verify_email_send {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/verifyemail", 'POST');
}

sub account_verify_email_status {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/verifyemail");
}

# Album
sub album {
    my $self = shift;
    my $id   = shift or die "missing required album id";
    return $self->request("/album/$id");
}

sub album_create {
    my $self = shift;
    my $opts = shift // {};
    my @opt_keys = (qw(ids deletehashes title description cover));
    my %valid_opts = map { $_ => 1 } @opt_keys;
    my $data = {};

    foreach my $opt (keys %{$opts}) {
        if (exists $valid_opts{$opt}) {
            my $key = $opt eq 'ids' || $opt eq 'deletehashes' ? $opt.'[]' : $opt;
            $data->{$key} = $opts->{$opt};
        }
    }

    return $self->request("/album", 'POST', $data);
}

sub album_delete {
    my $self = shift;
    my $id   = shift or die "missing required album id";
    return $self->request("/album/$id", 'DELETE');
}

sub album_favorite {
    my $self = shift;
    my $id   = shift or die "missing required album id";
    return $self->request("/album/$id/favorite", 'POST');
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
    return $self->request("/album/$album_id/add", 'POST', {'ids[]' => $image_ids});
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
    return $self->request("/album/$album_id", 'POST', {'ids[]' => $image_ids});
}

sub album_update {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $opts = shift // {};
    my %valid_opts = map { $_ => 1 } (qw(ids deletehashes title description cover));
    my $data = {};

    foreach my $opt (keys %{$opts}) {
        if (exists $valid_opts{$opt}) {
            my $key = $opt eq 'ids' || $opt eq 'deletehashes' ? $opt.'[]' : $opt;
            $data->{$key} = $opts->{$opt};
        }
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
    my $comment_id = shift or die "missing required comment id";
    return $self->request("/comment/$comment_id", 'DELETE');
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
        'comment'  => $comment,
    };

    return $self->request("/comment/$comment_id", 'POST', $data);
}

# TODO: test this
sub comment_report {
    my $self = shift;
    my $comment_id = shift or die "missing required comment_id";
    my $reason = shift;
    my $data = {};

    $data->{'reason'} = $reason if $reason;

    return $self->request("/comment/$comment_id/report", 'POST', $data);
}

sub comment_vote {
    my $self = shift;
    my $comment_id = shift or die "missing required comment_id";
    my $vote = shift or die "missing required vote";

    return $self->request("/comment/$comment_id/vote/$vote", 'POST');
}

# Gallery
sub gallery {
    my $self = shift;
    my $opts = shift // {};

    die "optional data must be a hashref" if ref $opts ne 'HASH';

    my $section    = $opts->{'section'} // 'hot';
    my $sort       = $opts->{'sort'} // 'viral';
    my $page       = $opts->{'page'} // 0;
    my $window     = $opts->{'window'} // 'day';
    my $show_viral = $opts->{'show_viral'} // 1;
    my $album_prev = $opts->{'album_previews'} // 1;

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
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'best';
    return $self->request("/gallery/$id/comments/$sort");
}

sub gallery_item_report {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $opts = shift // {};
    my $reason = $opts->{'reason'};
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
    my $opts = shift // {};
    my $advanced = shift // {};
    my $sort = $opts->{'sort'} // 'time';
    my $window = $opts->{'window'} // 'all';
    my $page = $opts->{'page'} // 0;
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
    my $opts = shift // {};
    my $data = {'title' => $title};

    if ($opts) {
        my @optional_keys = ('topic', 'terms', 'mature', 'tags');
        foreach my $key (keys %{$opts}) {
            if (first { $_ eq $key } @optional_keys) {
                if ($key eq 'tags') {
                    if (ref $opts->{'tags'} eq 'ARRAY') {
                        $opts->{'tags'} = join(',', @{$opts->{'tags'}});
                    }
                }
                $data->{$key} = $opts->{$key};
            }
        }
    }

    return $self->request("/gallery/image/$image_id", "POST", $data);
}

sub gallery_share_album {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    my $title = shift or die "missing required title";
    my $opts = shift // {};
    my $data = {'title' => $title};

    if ($opts) {
        my @optional_keys = ('topic', 'terms', 'mature', 'tags');
        foreach my $key (keys %{$opts}) {
            if (first { $_ eq $key } @optional_keys) {
                if ($key eq 'tags') {
                    if (ref $opts->{'tags'} eq 'ARRAY') {
                        $opts->{'tags'} = join(',', @{$opts->{'tags'}});
                    }
                }
                $data->{$key} = $opts->{$key};
            }
        }
    }

    return $self->request("/gallery/album/$album_id", "POST", $data);
}

sub gallery_subreddit {
    my $self = shift;
    my $subreddit = shift or die "missing required subreddit";
    my $opts = shift // {};

    die "optional data must be a hashref" if ref $opts ne 'HASH';

    my $sort = $opts->{'sort'} // 'time';
    my $window = $opts->{'window'} // 'week';
    my $page = $opts->{'page'} // 0;

    return $self->request(("/gallery/r/$subreddit/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_subreddit_image {
    my $self = shift;
    my $subreddit = shift or die "missing required subreddit";
    my $image_id = shift or die "missing required image id";

    return $self->request("/gallery/r/$subreddit/$image_id");
}

sub gallery_tag {
    my $self   = shift;
    my $tag    = shift or die "missing required tag";
    my $opts   = shift // {};
    my $sort   = $opts->{'sort'} // 'viral';
    my $page   = $opts->{'page'} // 0;
    my $window = $opts->{'window'} // 'week';

    return $self->request(("/gallery/t/$tag/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_tag_info {
    my $self = shift;
    my $tag  = shift or die "missing required tag";
    return $self->request("/gallery/tag_info/$tag");
}

sub gallery_tags {
    my $self = shift;
    return $self->request("/tags");
}

# Image
sub image {
    my $self = shift;
    my $id   = shift or die "missing required image id";
    return $self->request("/image/$id");
}

sub image_upload {
    my $self = shift;
    my $src  = shift or die "missing required image/video src";
    my $type = shift or die "missing required image/video type";
    my $opts = shift // {};
    my $data = {'image' => $src, 'type' => $type};
    my %hdrs = ();

    $data->{'title'} = $opts->{'title'} if $opts->{'title'};
    $data->{'description'} = $opts->{'description'} if $opts->{'description'};

    if ($type eq 'file') {
        die "file doesnt exist at path: $src" unless -e $src;
        die "provided src file path is not a file" unless -f $src;
        $data->{'image'} = [$src];
        $hdrs{Content_Type} = 'form-data';
    }

    return $self->request("/image", 'POST', $data, \%hdrs);
}

sub image_delete {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/image/$id", 'DELETE');
}

sub image_favorite {
    my $self = shift;
    my $id   = shift or die "missing required image id";
    return $self->request("/image/$id/favorite", 'POST');
}

sub image_update {
    my $self = shift;
    my $id   = shift or die "missing required image id";
    my $opts = shift // {};
    return $self->request("/image/$id", 'POST', $opts);
}

# Feed
sub feed {
    my $self = shift;
    return $self->request("/feed");
}

=head1 NAME


=head1 DESCRIPTION


=head1 SYNOPSIS


=head1 AUTHOR

Dillan Hildebrand

=head1 LICENSE

MIT

=head1 INSTALLATION


=cut

1;
