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

BEGIN {
    # Set PERL_LWP_SSL_VERIFY_HOSTNAME to 0 or
    # request to Imgur's API will return SSL ERRORS
    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
}

use constant {
    false => 0,
    true  => 1
};

use constant ENDPOINTS => {
    'IMGUR'           => 'https://api.imgur.com/3',
    'MASHAPE'         => 'https://imgur-apiv3.p.mashape.com',
    'OAUTH_ADDCLIENT' => 'https://api.imgur.com/oauth2/addclient',
    'OAUTH_AUTHORIZE' => 'https://api.imgur.com/oauth2/authorize',
    'OAUTH_TOKEN'     => 'https://api.imgur.com/oauth2/token',
    'OAUTH_SECRET'    => 'https://api.imgur.com/oauth2/secret'
};

use constant ALLOWED_FIELDS => {
    'ALBUM'           => ('ids', 'title', 'description', 'privacy', 'layout', 'cover'),
    'ADVANCED_SEARCH' => ('q_all', 'q_any', 'q_exactly', 'q_not', 'q_type', 'q_size_px'),
    'ACCOUNT'         => ('bio', 'public_images', 'messaging_enabled', 'album_privacy', 'accepted_gallery_terms', 'username'),
    'IMAGE'           => ('album', 'name', 'title', 'description')
};

# Hash which all member variables will be stored in
my %m_vars;

#-----------------------------------
# Constructor
#-----------------------------------
sub new {
    my $this   = bless {}, shift;
    my $obj_id = ident $this;

    $m_vars{ $obj_id }{'auth'}               = true;
    $m_vars{ $obj_id }{'client_id'}          = shift;
    $m_vars{ $obj_id }{'client_secret'}      = shift;
    $m_vars{ $obj_id }{'refresh_token'}      = shift;
    $m_vars{ $obj_id }{'expiration_time'}    = '';
    $m_vars{ $obj_id }{'format_type'}        = 'json';
    $m_vars{ $obj_id }{'response_type'}      = 'pin';
    $m_vars{ $obj_id }{'lwp_user_agent'}     = new LWP::UserAgent;
    $m_vars{ $obj_id }{'last_response_code'} = undef;
    $m_vars{ $obj_id }{'full_responses'}     = true;
    $m_vars{ $obj_id }{'verbose_output'}     = false;

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

    return false if not defined $response->{'access_token'};

    $m_vars{ $obj_id }{'access_token'}   = $response->{'access_token'};
    $m_vars{ $obj_id }{'refresh_token'}  = $response->{'refresh_token'}; 
    $m_vars{ $obj_id }{'exiration_time'} = DateTime->now;

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

    my $expiration_time = DateTime->now;
       $expiration_time->add( hours => 1 );

    my $m_rt = \$m_vars{ $obj_id }{'refresh_token'};
    my $m_at = \$m_vars{ $obj_id }{'access_token'};
    my $m_et = \$m_vars{ $obj_id }{'expires_in'};

    my $r_rt = \$response->{'refresh_token'};
    my $r_at = \$response->{'access_token'};
    my $r_et = \$response->{'expires_in'};

    $$m_rt = (defined $$r_rt && length $$r_rt ? $$r_rt : $$m_rt);
    $$m_at = (defined $$r_at && length $$r_at ? $$r_at : $$m_at);
    $$m_et = (defined $$r_et && length $$r_et ? $$r_et : $$m_et);
                                             
    return (defined $response->{'data'}{'status'} ? $response->{'data'}{'status'} : 200);
}

#-----------------------------------
# API Request
#-----------------------------------
sub request {
    my ($this, $uri, $http_method, $post_data) = @_;
    my $obj_id = ident $this;

    die("Error: you must provide a client id before making requests.\n")     
        unless (defined $m_vars{ $obj_id }{'client_id'} and length $m_vars{ $obj_id }{'client_id'});
    
    my $response   = undef;
    my $request    = undef;
    my $end_point  = (defined $m_vars{ $obj_id }{'MASHAPE_KEY'} ? ENDPOINTS->{'MASHAPE'} . $uri : ENDPOINTS->{'IMGUR'} . $uri);
       $end_point  = ($uri =~ /^http(?:s)?/ ? $uri : $end_point);
       $end_point .= '?_format=xml' if $this->get_format_type() eq 'xml';

    $http_method ||= 'GET';
    $http_method   = lc($http_method);

    # Reset the last response code
    $this->{'last_response_code'} = undef;
    
    if($http_method eq 'post') {
        $response = $m_vars{ $obj_id }{'lwp_user_agent'}->post($end_point, $post_data);
    }
    elsif($http_method =~ m/^(?:get|delete)$/) {   

        say "Endpoint: $end_point";

        # Fire!
        $request  = new HTTP::Request(GET => $end_point);
        $response = $m_vars{ $obj_id }{'lwp_user_agent'}->request($request);
        
        $m_vars{ $obj_id }{'x_ratelimit_userlimit'}      = $response->{'_headers'}{'x-ratelimit-userlimit'};
        $m_vars{ $obj_id }{'x_ratelimit_userremaining'}  = $response->{'_headers'}{'x-ratelimit-userremaining'};
        $m_vars{ $obj_id }{'x_ratelimit_userreset'}      = $response->{'_headers'}{'x-ratelimit-userreset'};
        $m_vars{ $obj_id }{'x_ratelimit_clientlimit'}    = $response->{'_headers'}{'x-ratelimit-clientlimit'};
        $m_vars{ $obj_id }{'x_ratelimit_lientremaining'} = $response->{'_headers'}{'x-ratelimit-clientremaining'};
    }
    
    if(defined $response->{'_rc'} && $response->{'_rc'} =~ m/^(200|400|401|403|404|429|500)$/) {
        $this->{'last_response_code'} = $1;
    }

    print Dumper($response) unless ! $m_vars{ $obj_id }{'verbose_output'};
    
    return ($m_vars{ $obj_id }{'full_response'} ? $response : $response->{'_content'});
}

sub auth_ini {
    my ($this, $auth_ini) = @_;
    my $obj_id = ident $this;

    die("Error: you must give a path to your INI auth file.\n") unless defined $auth_ini;
    die("Error: $auth_ini doesn't exist.\n") unless -f $auth_ini;

    $m_vars{ $obj_id }{'auth'}            = true;
    $m_vars{ $obj_id }{'auth_ini'}        = Config::IniFiles->new(-file => $auth_ini);
    $m_vars{ $obj_id }{'client_id'}       = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'client_id');
    $m_vars{ $obj_id }{'client_secret'}   = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'client_secret');
    $m_vars{ $obj_id }{'access_token'}    = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'access_token');
    $m_vars{ $obj_id }{'refresh_token'}   = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'refresh_token');
    $m_vars{ $obj_id }{'expiration_time'} = $m_vars{ $obj_id }{'auth_ini'}->val('Credentials', 'expiration_time');

    my $et = \$m_vars{ $obj_id }{'expiration_time'};
    my $dt = undef;
       $dt = DateTime::Format::ISO8601->parse_datetime($$et) unless !$$et;

    if((!$$et) || 
        ($$et && (defined $dt && DateTime->now() >= $dt))) {
        say "Refreshing";

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
    my $obj_id   = ident shift;
    my $auth_ini = \$m_vars{ $obj_id }{'auth_ini'};

    $$auth_ini->setval('Credentials', 'access_token',    $m_vars{ $obj_id }{'access_token'});
    $$auth_ini->setval('Credentials', 'refresh_token',   $m_vars{ $obj_id }{'refresh_token'});
    $$auth_ini->setval('Credentials', 'expiration_time', $m_vars{ $obj_id }{'expiration_time'});
    $$auth_ini->RewriteConfig();
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
sub set_no_auth         { $m_vars{ ident shift }{'auth'}            = false; }
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

sub get_album {
    my ($this, $album_id) = @_;
    die("Error: invalid album id.\n") unless $album_id =~ /^(?:\d+)$/;
    return $this->request("/album/$album_id");
}

sub get_album_images {
    my ($this, $id) = @_;
    return $this->request("/album/$id/images");
}

#--------------
# Albums
#--------------
sub album_create {
    my ($this, $data) = @_;
    print Dumper($data);
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

sub album_delete_images {
    my ($this, $id, $image_ids) = @_;
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

# TODO:
sub get_user_galleries {
    my $this = shift;
    return $this->request('/g');
}

# TODO:
sub create_custom_gallery {
    my ($this, $name, $tags) = @_;
    $tags ||= '';
}

# TODO:
sub custom_gallery_update {
    my ($this, $id, $name) = @_;

}

sub custom_gallery_add_tags {
    my ($this, $id, $tags) = @_;

}

sub custom_gallery_remove_tags {
    my ($id, $tags) = @_;
}

sub custom_gallery_delete {
    my ($this, $id) = @_;
}

sub filtered_out_tags {
    my $this = shift;
}

sub block_tag {
    my ($this, $tag) = @_;
}

sub unblock_tag {
    my ($this, $tag) = @_;
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
}

sub memes_subgallery {
    my ($this, $sort, $page, $window) = @_;
    $sort ||= 'viral';
}

sub memes_subgallery_image {
    my ($this, $id) = @_;
}

sub subreddit_gallery {
    my ($this, $subreddit, $sort, $window, $page) = @_;
}

sub subreddit_image {
    my ($this, $subreddit, $id) = @_;
}

sub gallery_tag {
    my ($this, $tag, $sort, $page, $window) = @_;
}

sub gallery_tag_image {

}

sub gallery_item_tags {

}

sub gallery_tag_vote {

}

sub gallery_search {

}

sub gallery_random {

}

sub share_on_imgur {

}

sub remove_from_gallery {

}

sub gallery_item {

}

sub report_gallery_item {

}

sub gallery_item_vote {

}

sub gallery_item_comments {

}

sub gallery_comment {

}

sub gallery_comment_ids {

} 

sub gallery_comment_count {

}

#--------------------
# Image
#--------------------
sub get_image {
    my ($this, $id) = @_;
    return $this->request("/image/$id");
}

sub upload_from_path {
    my ($this, $path, $config, $anon) = @_;
}

sub upload_from_url {
    my ($this, $url, $config, $anon) = @_;
}

sub delete_image {
    my ($this, $id) = @_;

}

sub favorite_image {
    my ($this, $id) = @_;
}

#--------------------
# Conversation
#--------------------

sub conversation_list {
    my $this = shift;
    return $this->request('/conversations');
}

sub get_conversation {
    my ($this, $id, $page, $offset) = @_;
    $page   ||= 0;
    $offset ||= 0;
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
# Notification
#--------------------
sub get_notifications {
    my ($this, $new) = @_;
    $new ||= true;
    #return $this->request("/account/$username/notifications");
}

sub get_notification {
    my ($this, $id) = @_;

}

sub mark_notifications_as_read {
    my ($this, $ids) = @_;

}

#--------------------
# Memegen
#--------------------
sub get_meme_metadata {
    my $this = shift;
    return $this->request("/g");
}

1;
