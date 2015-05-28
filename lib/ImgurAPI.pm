#!/usr/bin/perl -w

package ImgurAPI;

use v5.010;
use strict;
use JSON qw( decode_json );
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;
use DateTime::Format::ISO8601;
use Config::IniFiles;
use Scalar::Util;
use Class::Std::Utils;
use MIME::Base64;
use File::Slurp;

BEGIN {
    # Set PERL_LWP_SSL_VERIFY_HOSTNAME to 0 or
    # request to Imgur's API will return SSL ERRORS
    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
}

use constant ENDPOINTS => {
    'IMGUR'           => 'https://api.imgur.com/3',
    'MASHAPE'         => 'https://imgur-apiv3.p.mashape.com',
    'OAUTH_ADDCLIENT' => 'https://api.imgur.com/oauth2/addclient',
    'OAUTH_AUTHORIZE' => 'https://api.imgur.com/oauth2/authorize',
    'OAUTH_TOKEN'     => 'https://api.imgur.com/oauth2/token',
    'OAUTH_SECRET'    => 'https://api.imgur.com/oauth2/secret'
};

# Hash which all member variables will be stored in
my %m_vars;

#-----------------------------------
# Constructor
#-----------------------------------
sub new {
    my $this   = bless {}, shift;
    my $obj_id = ident $this;

    $m_vars{ $obj_id }{'auth'}               = 1;
    $m_vars{ $obj_id }{'client_id'}          = shift;
    $m_vars{ $obj_id }{'client_secret'}      = shift;
    $m_vars{ $obj_id }{'refresh_token'}      = shift;
    $m_vars{ $obj_id }{'expiration_time'}    = '';
    $m_vars{ $obj_id }{'format_type'}        = 'json';
    $m_vars{ $obj_id }{'response_type'}      = 'pin';
    $m_vars{ $obj_id }{'lwp_user_agent'}     = new LWP::UserAgent;
    $m_vars{ $obj_id }{'last_response_code'} = 0;
    $m_vars{ $obj_id }{'full_responses'}     = 1;
    $m_vars{ $obj_id }{'verbose_output'}     = 0;

    # Default headers
    $this->set_headers();
    
    return $this;
}

#-----------------------------------
# Authorize
#-----------------------------------
sub authorize {
    my $this          = shift;
    my $obj_id        = ident $this;
    my $response      = undef;
    my $response_type = \$m_vars{ $obj_id }{'response_type'};

    if(lc($$response_type) eq 'pin') {
        my $content = {
            'client_id'     => $m_vars{ $obj_id }{'client_id'},
            'client_secret' => $m_vars{ $obj_id }{'client_secret'},
            'grant_type'    => 'pin',
            'pin'           => $m_vars{ $obj_id }{'auth_pin'}
        };

        $response = decode_json('', $content, 'POST');
    }

    if(defined $response->{'data'}{'error'}) {
        return $response->{'status'} unless $response->{'status'} == 400;
        
        die("Error: you must provide a refresh_token.\n")    unless length $m_vars{ $obj_id }{'refresh_token'};
        die("Error: refresh_token must be 40 characters.\n") unless length $m_vars{ $obj_id }{'refresh_token'} == 40;
        
        return $this->refresh();
    }

    return 0 if not defined $response->{'access_token'};

    $m_vars{ $obj_id }{'access_token'}    = $response->{'access_token'};
    $m_vars{ $obj_id }{'refresh_token'}   = $response->{'refresh_token'}; 
    $m_vars{ $obj_id }{'expiration_time'} = DateTime->now;
    $m_vars{ $obj_id }{'expiration_time'}->add( hours => 1);

    $this->set_headers();

    print Dumper($response) unless ! $m_vars{ $obj_id }{'verbose_output'};

    return 200;
}

#-----------------------------------
# Refresh access token
#-----------------------------------
sub refresh {
    my $this      = shift;
    my $obj_id    = ident $this;
    my $post_data = {
        'refresh_token' => $m_vars{ $obj_id }{'refresh_token'},
        'client_id'     => $m_vars{ $obj_id }{'client_id'},
        'client_secret' => $m_vars{ $obj_id }{'client_secret'},
        'grant_type'    => 'refresh_token'
    };

    my $response = $this->request(ENDPOINTS->{'OAUTH_TOKEN'}, 'POST', $post_data);
       $response = decode_json($response) if length $response;


    $m_vars{ $obj_id }{'expiration_time'} = DateTime->now;
    $m_vars{ $obj_id }{'expiration_time'}->add( hours => 1 );

    my $m_rt = \$m_vars{ $obj_id }{'refresh_token'};
    my $m_at = \$m_vars{ $obj_id }{'access_token'};
    my $r_rt = \$response->{'refresh_token'};
    my $r_at = \$response->{'access_token'};
      $$m_rt = (defined $$r_rt && length $$r_rt ? $$r_rt : $$m_rt);
      $$m_at = (defined $$r_at && length $$r_at ? $$r_at : $$m_at);
                                             
    return (defined $response->{'data'}{'status'} ? $response->{'data'}{'status'} : 200);
}

#-----------------------------------
# API Request
#-----------------------------------
sub request {
    my ($this, $uri, $http_method, $post_data) = @_;
    my $obj_id = ident $this;

    $post_data   ||= undef;
    $http_method ||= 'GET';
    $http_method   = lc($http_method);

    die("Error: you must provide a client id before making requests.\n")     
        unless (defined $m_vars{ $obj_id }{'client_id'} and length $m_vars{ $obj_id }{'client_id'});

    my $response   = undef;
    my $request    = undef;
    my $end_point  = (defined $m_vars{ $obj_id }{'MASHAPE_KEY'} ? ENDPOINTS->{'MASHAPE'} . $uri : ENDPOINTS->{'IMGUR'} . $uri);
       $end_point  = ($uri =~ /^http(?:s)?/ ? $uri : $end_point);
       $end_point .= '?_format=' . ($this->get_format_type() eq 'xml' ? 'xml' : 'json');
       $end_point .= "&_method=$http_method";

    # Reset the last response code
    $m_vars{ $obj_id }{'last_response_code'} = undef;
    
    if($http_method eq 'post') {
        $response = $m_vars{ $obj_id }{'lwp_user_agent'}->post($end_point, $post_data);
    }
    elsif($http_method =~ m/^(?:get|delete)$/) { 
        if(scalar keys %$post_data) {
            while(my ($key, $value) = each %$post_data) {
                $end_point .= "&$key=$value";
            }
        }

        # Fire!
        $request  = ($http_method eq 'get' ? new HTTP::Request(GET => $end_point) : new HTTP::Request(DELETE => $end_point));
        $response = $m_vars{ $obj_id }{'lwp_user_agent'}->request($request);
        
        $m_vars{ $obj_id }{'x_ratelimit_userlimit'}      = $response->{'_headers'}{'x-ratelimit-userlimit'};
        $m_vars{ $obj_id }{'x_ratelimit_userremaining'}  = $response->{'_headers'}{'x-ratelimit-userremaining'};
        $m_vars{ $obj_id }{'x_ratelimit_userreset'}      = $response->{'_headers'}{'x-ratelimit-userreset'};
        $m_vars{ $obj_id }{'x_ratelimit_clientlimit'}    = $response->{'_headers'}{'x-ratelimit-clientlimit'};
        $m_vars{ $obj_id }{'x_ratelimit_lientremaining'} = $response->{'_headers'}{'x-ratelimit-clientremaining'};
    }
    
    if(defined $response->{'_rc'} && $response->{'_rc'} =~ m/^(200|400|401|403|404|429|500)$/) {
        $m_vars{ $obj_id }{'last_response_code'} = $1;
    }

    print Dumper($response) unless ! $m_vars{ $obj_id }{'verbose_output'};
    
    return ($m_vars{ $obj_id }{'full_response'} ? $response : $response->{'_content'});
}

sub auth_ini {
    my ($this, $auth_ini) = @_;
    my $obj_id = ident $this;

    die("Error: you must give a path to your INI auth file.\n") unless defined $auth_ini;
    die("Error: $auth_ini doesn't exist.\n") unless -f $auth_ini;

    $m_vars{ $obj_id }{'auth'}            = 1;
    $m_vars{ $obj_id }{'auth_ini'}        = Config::IniFiles->new(-file => $auth_ini);
    $m_vars{ $obj_id }{'client_id'}       = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'client_id');
    $m_vars{ $obj_id }{'client_secret'}   = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'client_secret');
    $m_vars{ $obj_id }{'access_token'}    = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'access_token');
    $m_vars{ $obj_id }{'refresh_token'}   = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'refresh_token');
    $m_vars{ $obj_id }{'expiration_time'} = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'expiration_time');

    my $et = \$m_vars{ $obj_id }{'expiration_time'};
    my $dt = undef;
       $dt = DateTime::Format::ISO8601->parse_datetime($$et) unless !$$et;

    if((!$$et) || ($$et && (defined $dt && DateTime->now() >= $dt))) {
        if($this->refresh() != 200) {
               $m_vars{ $obj_id }{'last_response_code'} = $this->authorize();
            if($m_vars{ $obj_id }{'last_response_code'} == 200) {
                $this->update_auth_ini();
            }
        }
        else {
            $this->update_auth_ini();
        }
    }

    $this->set_headers();
}

sub update_auth_ini {
    my $this = shift;
    my $obj_id = ident $this;

    $m_vars{ $obj_id }{'auth_ini'}->setval('Credentials', 'access_token',    $m_vars{ $obj_id }{'access_token'});
    $m_vars{ $obj_id }{'auth_ini'}->setval('Credentials', 'refresh_token',   $m_vars{ $obj_id }{'refresh_token'});
    $m_vars{ $obj_id }{'auth_ini'}->setval('Credentials', 'expiration_time', $m_vars{ $obj_id }{'expiration_time'});
    $m_vars{ $obj_id }{'auth_ini'}->RewriteConfig();
}

#-----------------------------------
# Setters
#-----------------------------------
sub set_format_type     { $m_vars{ ident shift }{'format_type'}     = shift; }
sub set_state           { $m_vars{ ident shift }{'state'}           = shift; }
sub set_auth_pin        { $m_vars{ ident shift }{'auth_pin'}        = shift; }
sub set_auth_token      { $m_vars{ ident shift }{'auth_token'}      = shift; }
sub set_auth_code       { $m_vars{ ident shift }{'auth_code'}       = shift; }
sub set_refresh_token   { $m_vars{ ident shift }{'refresh_token'}   = shift; }
sub set_expiration_time { $m_vars{ ident shift }{'expiration_time'} = shift; }
sub set_no_auth         { $m_vars{ ident shift }{'auth'}            = 0;     }
sub set_verbose_output  { $m_vars{ ident shift }{'verbose_output'}  = shift; }
sub set_client_id       { $m_vars{ ident shift }{'client_id'}       = shift;
    set_headers();
}

sub set_headers {
    my $obj_id         = ident shift;
    my $lwp_user_agent = \$m_vars{ $obj_id }{'lwp_user_agent'};
    my $client_id      = \$m_vars{ $obj_id }{'client_id'};
    my $access_token   = \$m_vars{ $obj_id }{'access_token'};
    my $auth           = \$m_vars{ $obj_id }{'auth'};

    $$lwp_user_agent->default_header('Authorization' => "Client-ID $$client_id") unless ! defined $$client_id;
    $$lwp_user_agent->default_header('Authorization' => "Bearer $$access_token") unless ! $$auth || ! $$access_token;
}

#-------------------------------------
# Getters
#-------------------------------------

sub get_auth_url {
    my $obj_id        = ident shift;
    my $client_id     = \$m_vars{ $obj_id }{'client_id'};
    my $response_type = \$m_vars{ $obj_id }{'response_type'};

    return (ENDPOINTS->{'OAUTH_AUTHORIZE'} . "?client_id=$$client_id&response_type=$$response_type");
}

sub get_auth_pin                    { return $m_vars{ ident shift }{'auth_pin'};                    }
sub get_auth_code                   { return $m_vars{ ident shift }{'auth_code'};                   }
sub get_auth_token                  { return $m_vars{ ident shift }{'auth_token'};                  } 
sub get_format_type                 { return $m_vars{ ident shift }{'format_type'}                  }
sub get_response_code               { return $m_vars{ ident shift }{'last_response_code'};          }
sub get_response_type               { return $m_vars{ ident shift }{'response_type'};               }
sub get_access_token                { return $m_vars{ ident shift }{'access_token'};                }
sub get_refresh_token               { return $m_vars{ ident shift }{'refresh_token'};               }
sub get_expiration_time             { return $m_vars{ ident shift }{'expiration_time'};             }
sub get_x_ratelimit_userlimit       { return $m_vars{ ident shift }{'x_ratelimit_userlimit'};       }
sub get_x_ratelimit_userremaining   { return $m_vars{ ident shift }{'x_ratelimit_userremaining'};   }
sub get_x_ratelimit_userreset       { return $m_vars{ ident shift }{'x_ratelimit_userreset'};       }
sub get_x_ratelimit_clientlimit     { return $m_vars{ ident shift }{'x_ratelimit_clientlimit'};     } 
sub get_x_ratelimit_clientremaining { return $m_vars{ ident shift }{'x_ratelimit_clientremaining'}; }

#-----------------------------------
# Account
#-----------------------------------
sub get_account {
    my ($this, $username) = @_;
    return $this->request("/account/$username");
}

sub get_gallery_favorites {
    my ($this, $username) = @_;
    return $this->request("/account/$username/gallery_favorites");
}

sub get_account_favorites {
    my ($this, $username) = @_;
    return $this->request("/account/$username/favorites");
}

sub get_account_submissions {
    my ($this, $username, $page) = @_;
    $page ||= 0;
    return $this->request("/account/$username/submissions/$page");
}

sub get_account_settings {
    my ($this, $username) = @_;
    return $this->request("/account/$username/settings");
}

sub send_verification_email {
    my ($this, $username) = @_;
    return $this->request("/account/$username/verifyemail", 'POST');
}

sub get_email_verification_status {
    my ($this, $username) = @_;
    return $this->request("/account/$username/verifyemail");
}

sub get_account_albums {
    my ($this, $username, $page) = @_;
    $page ||= 0;
    return $this->request("/account/$username/albums/$page");
}

sub get_account_album_ids {
    my ($this, $username, $page) = @_;
    $page ||= 0;
    return $this->request("/account/$username/ids/$page");
}

sub get_account_album_count {
    my ($this, $username) = @_;
    return $this->request("/account/$username/albums/count");
}

sub get_account_comments {
    my ($this, $username, $sort, $page) = @_;
    $sort ||= 'newest';
    $page ||= 0;
    return $this->request("/account/$username/comments/$sort/$page");
}

sub get_account_comment_ids {
    my ($this, $username, $sort, $page) = @_;
    $sort ||= 'newest';
    $page ||= 0;
    return $this->request("/account/$username/comments/$sort/$page");
}

sub get_account_comment_count {
    my ($this, $username) = @_;
    return $this->request("/account/$username/comments/count");
}

sub change_account_settings {
    my ($this, $username, $settings) = @_;
    my %valid_setting_fields = map { $_ => 1 } ('bio', 'public_images', 'messaging_enabled', 'album_privacy', 'accepted_gallery_terms', 'username');
    my $data = {};

    die("Error: you must provide a hashref to the new account settings\n") unless $settings;

    foreach my $key (keys %{ $settings }) {
        $data->{ $key } = $settings->{ $key } unless ! exists($valid_setting_fields{ $key });
    }

    return $this->request("/account/$username/settings", 'POST', $data);
}

#--------------
# Albums
#--------------

sub get_album {
    my ($this, $id) = @_;
    return $this->request("/album/$id");
}

sub get_album_images {
    my ($this, $id) = @_;
    return $this->request("/album/$id/images");
}

sub album_create {
    my ($this, $fields) = @_;
    my %valid_album_keys = map { $_ => 1 } ('ids', 'title', 'description', 'privacy', 'layout', 'cover');
    my $data = {};

    die("Error: you must provide fields when creating an album\n") unless $fields;

    foreach my $key (keys %{ $fields }) {
        $data->{ $key } = $fields->{ $key } unless ! exists($valid_album_keys{ $key });
    }

    return $this->request("/album", 'POST', $data);
}

sub album_update {
    my ($this, $id) = @_;
}

sub album_delete {
    my ($this, $id) = @_;
    return $this->request("/album/$id", 'DELETE');
}

sub album_favorite {
    my ($this, $id) = @_;
    return $this->request("/album/$id/favorite", 'POST');
}

sub album_set_images {
    my ($this, $id, $image_ids) = @_;
    return $this->request("/album/$id/", 'POST', $image_ids);
}

sub album_add_images {
    my ($this, $id, $image_ids) = @_;
    return $this->request("/album/$id/add", 'POST', $image_ids);
}

sub album_remove_images {
    my ($this, $id, @image_ids) = @_;
    return $this->request("/album/$id/remove_images", 'DELETE', {'ids' => join(',', @image_ids)});
}

#--------------
# Comments
#--------------
sub get_comment {
    my ($this, $id) = @_;
    return $this->request("/comment/$id");
}

sub delete_comment {
    my ($this, $id) = @_;
    return $this->request("/comment/$id", 'DELETE');
}

sub get_comment_replies {
    my ($this, $id) = @_;
    return $this->request("/comment/$id/repies");
}

sub post_comment_reply {
    my ($this, $image_id, $comment_id, $comment) = @_;
    my $data = {
        'image_id'   => $image_id,
        'comment_id' => $comment_id,
        'comment'    => $comment
    };

    $this->request("/comment/$comment_id", 'POST', $data);
}

sub comment_vote {
    my ($this, $id, $vote) = @_;
    $vote ||= 'up';
    return $this->request("/comment/$id/vote/$vote", 'POST');
}

sub report_comment {
    my ($this, $id) = @_;
    return $this->request("/comment/$id/report", 'POST');
}

#--------------------
# Custom galleries
#--------------------
sub get_custom_gallery {
    my ($this, $id, $sort, $window, $page) = @_;
    $sort   ||= 'viral';
    $window ||= 'week';
    $page   ||= 0;
    return $this->request("/g/$id/$sort/$window/$page");
}

sub get_user_galleries {
    my $this = shift;
    return $this->request("/g");
}

sub create_custom_gallery {
    my ($this, $name, @tags) = @_;
    return $this->request("/g", 'POST', { 'name' => $name });
}

sub custom_gallery_update {
    my ($this, $id, $name) = @_;
    return $this->request("/g/$id", 'POST', { 'id' => $id, 'name' => $name })
}

sub custom_gallery_add_tags {
    my ($this, $id, @tags) = @_;
    return $this->request("/g/$id/add_tags", 'PUT', { 'tags' => join(',', @tags) });
}

sub custom_gallery_remove_tags {
    my ($this, $id, @tags) = @_;
    return $this->request("/g/$id/remove_tags", 'DELETE', { 'tags' => join(',', @tags) });
}

sub custom_gallery_delete {
    my ($this, $id) = @_;
    return $this->request("/g/$id", 'DELETE');
}

sub filtered_out_tags {
    my $this = shift;
    return $this->request("/g/filtered_out");
}

sub block_tag {
    my ($this, $tag) = @_;
    return $this->request("/g/block_tag", 'POST', { 'tag' => $tag });
}

sub unblock_tag {
    my ($this, $tag) = @_;
    return $this->request("/g/unblock_tag", 'POST', { 'tag' => $tag });
}

#--------------------
# Gallery
#--------------------
sub gallery {
    my ($this, $section, $sort, $page, $window, $show_viral) = @_;
    $section    ||= 'hot';
    $sort       ||= 'viral';
    $page       ||= 0;
    $window     ||= 'day';
    $show_viral ||= 1;
    return $this->request(("/gallery/$section/$sort" . ($section eq 'top' ? "/$window" : "") . "/$page?showViral=$show_viral"));
}

sub memes_subgallery {
    my ($this, $sort, $page, $window) = @_;
    $sort   ||= 'viral';
    $page   ||= 0;
    $window ||= 'week';
    return $this->request(("/g/memes/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub memes_subgallery_image {
    my ($this, $id) = @_;
    return $this->request("/g/memes/$id");
}

sub subreddit_gallery {
    my ($this, $subreddit, $sort, $window, $page) = @_;
    $sort   ||= 'time';
    $window ||= 'week';
    $page   ||= 0;
    return $this->request(("/gallery/r/$subreddit/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub subreddit_image {
    my ($this, $subreddit, $id) = @_;
    return $this->request("/gallery/r/$subreddit/$id");
}

sub gallery_tag {
    my ($this, $tag, $sort, $page, $window) = @_;
    $sort   ||= 'viral';
    $page   ||= 0;
    $window ||= 'week';
    return $this->request(("/gallery/t/$tag/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_tag_image {
    my ($this, $tag, $id) = @_;
    return $this->request("/gallery/t/$tag/$id");
}

sub gallery_item_tags {
    my ($this, $id) = @_;
    return $this->request("/gallery/$id/tags");
}

sub gallery_tag_vote {
    my ($this, $id, $tag, $vote) = @_;
    return $this->response("/gallery/$id/vote/tag/$tag/$vote", 'POST');
}

sub gallery_search {
    my ($this, $query, $fields, $sort, $window, $page) = @_;
    $fields ||= {};
    $sort   ||= 'time';
    $window ||= 'all';
    $page   ||= 0;

    my $data = {};

    if($fields) {
        my %valid_search_keys = map { $_ => 1 } ('q_all', 'q_any', 'q_exactly', 'q_not', 'q_type', 'q_size_px');

        foreach my $key (keys %{ $fields }) {
            $data->{ $key } = $fields->{ $key } unless ! exists($valid_search_keys{ $key });
        }
    }
    else {
        $data->{'q'} = $query;
    }

    return $this->request("/gallery/search/$sort/$window/$page", 'GET', $data);
}

sub gallery_random {
    my ($this, $page) = @_;
    return $this->request("/gallery/random/random/$page");
}

sub share_on_imgur {
    my ($this, $id, $title, $terms) = @_;
    $terms ||= 0;
    return $this->request("/gallery/$id", 'POST', { 'title' => $title, 'terms' => $terms });
}

sub remove_from_gallery {
    my ($this, $id) = @_;
    return $this->request("/gallery/$id", 'DELETE');
}

sub gallery_item {
    my ($this, $id) = @_;
    return $this->request("/gallery/$id");
}

sub report_gallery_item {
    my ($this, $id) = @_;
    return $this->request("/gallery/$id/report", 'POST');
}

sub gallery_item_vote {
    my ($this, $id, $vote) = @_;
    $vote ||= 'up';
    return $this->request("/gallery/$id/vote/$vote", 'POST');
}

sub gallery_item_comments {
    my ($this, $id, $sort) = @_;
    $sort ||= 'best';
    return $this->request("/gallery/$id/comments/$sort");
}

sub gallery_comment {
    my ($this, $id, $comment) = @_;
    return $this->request("/gallery/$id/comment", 'POST', { 'comment' => $comment });
}

sub gallery_comment_ids {
    my ($this, $id) = @_;
    return $this->request("/gallery/$id/comments/ids");
} 

sub gallery_comment_count {
    my ($this, $id) = @_;
    return $this->request("/gallery/$id/comments/count");
}

#--------------------
# Images
#--------------------
sub get_image {
    my ($this, $id) = @_;
    return $this->request("/image/$id");
}

sub upload_from_path {
    my ($this, $path, $fields, $anon) = @_;
    $fields ||= {};
    $anon   ||= 0;

    my $image_data = read_file($path);
    my $data       = {
        'image' => encode_base64($image_data),
        'type'  => 'base64'
    };

    if($fields) {
        my %valid_image_keys = map { $_ => 1 } ('album', 'name', 'title', 'description');

        foreach my $key (keys %{ $fields }) {
            $data->{ $key } = $fields->{ $key } unless ! exists($valid_image_keys{ $key });
        }
    }

    return $this->request("/upload", 'POST', $data);
}

sub upload_from_url {
    my ($this, $url, $fields, $anon) = @_;

    $fields ||= {};
    $anon   ||= 0;

    my $data = {
        'image' => $url,
        'type'  => 'url'
    };

    if($fields) {
        my %valid_image_keys = map { $_ => 1 } ('album', 'name', 'title', 'description');

        foreach my $key (keys %{ $fields }) {
            $data->{ $key } = $fields->{ $key } unless ! exists($valid_image_keys{ $key });
        }
    }

    return $this->request("/upload", 'POST', $data);
}

sub delete_image {
    my ($this, $id) = @_;
    return $this->request("/image/$id", 'DELETE');
}

sub favorite_image {
    my ($this, $id) = @_;
    return $this->request("/image/$id/favorite", 'POST');
}

#--------------------
# Conversations
#--------------------

sub conversation_list {
    my $this = shift;
    return $this->request("/conversations");
}

sub get_conversation {
    my ($this, $id, $page, $offset) = @_;
    $page   ||= 0;
    $offset ||= 0;
    return $this->request("/conversations/$id/$page/$offset");
}

sub create_message {
    my ($this, $recipient, $body) = @_;
    return $this->request("/conversations/$recipient", 'POST', { 'body' => $body });
}

sub delete_conversation {
    my ($this, $id) = @_;
    return $this->request("/conversations/$id", 'DELETE');
}

sub report_sender {
    my ($this, $username) = @_;
    return $this->request("/conversations/report/$username", 'POST');
}

sub block_sender {
    my ($this, $username) = @_;
    return $this->request("/conversations/block/$username", 'POST');
}

#--------------------
# Notifications
#--------------------
sub get_notifications {
    my ($this, $new) = @_;
    $new ||= 1;
    return $this->request("/notification", 'GET', { 'new' => $new });
}

sub get_notification {
    my ($this, $id) = @_;
    return $this->request("/notification/$id");
}

sub mark_notifications_as_read {
    my ($this, @ids) = @_;
    return $this->request("/notification", 'POST', { 'ids' => join(',', @ids) });
}

#--------------------
# Memegen
#--------------------
sub get_default_memes {
    my $this = shift;
    return $this->request("/memegen/defaults");
}

1;
