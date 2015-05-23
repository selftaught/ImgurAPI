#!/usr/bin/perl -w

package ImgurAPI;

use v5.010;
use strict;
use Config;
use JSON qw( decode_json );
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;
use DateTime;

BEGIN {
    # Set PERL_LWP_SSL_VERIFY_HOSTNAME to 0 or
    # request to Imgur's API will return SSL ERRORS
    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
}

use constant {
    false => 0,
    true  => 1
};

use constant ENDPOINT_URLS => {
    'IMGUR'           => 'https://api.imgur.com/3',
    'MASHAPE'         => 'https://imgur-apiv3.p.mashape.com',
    'OAUTH_ADDCLIENT' => 'https://api.imgur.com/oauth2/addclient',
    'OAUTH_AUTHORIZE' => 'https://api.imgur.com/oauth2/authorize',
    'OAUTH_TOKEN'     => 'https://api.imgur.com/oauth2/token',
    'OAUTH_SECRET'    => 'https://api.imgur.com/oauth2/secret'
};

#-----------------------------------
# Constructor
#-----------------------------------
sub new {
	my $class = shift;
	my $this  = {
        'auth'                => true, 
		'client_id'           => shift,
		'client_secret'       => shift,
        'refresh_token'       => shift,
        'expiration_datetime' => '',
        'response_type'       => 'pin',
		'lwp_user_agent'      => new LWP::UserAgent,
		'last_response_code'  => undef,
		'full_responses'      => true
	};

    # Default headers
    $this->{'lwp_user_agent'}->default_header('Authorization' => "Client-ID $this->{'client_id'}");

	die("Error: you must provide a client id.\n")     
        unless (defined $this->{'client_id'} and length $this->{'client_id'});

	die("Error: you must provide a client secret.\n") 
        unless (defined $this->{'client_secret'} and length $this->{'client_secret'});

	return (bless $this, $class);
}

#-----------------------------------
# Authorize
#-----------------------------------
sub authorize {
    my $this          = shift;
    my $response      = undef;
    my $response_type = $this->{'response_type'};

    if($response_type eq 'pin') {
        my $content = {
            'client_id'     => $this->{'client_id'},
            'client_secret' => $this->{'client_secret'},
            'grant_type'    => 'pin',
            'pin'           => $this->{'pin'}
        };

        $response = decode_json($this->request(ENDPOINT_URLS->{'OAUTH_TOKEN'}, $content, 'POST'));
    }
    elsif($response_type eq 'token') {
        
    }
    elsif($response_type eq 'code') {

    }

    print Dumper($response);

    if(defined $response->{'data'}{'error'}) {
        # Don't try to retrieve another access_token if
        # the status code is anything other than 400
        if($response->{'status'} != 400) {
            return $response->{'status'};
        }

        die("Error: you must provide a refresh_token.\n")    
            unless length $this->{'refresh_token'};

        die("Error: refresh_token must be 40 characters.\n") 
            unless length $this->{'refresh_token'} == 40;
        
        return $this->refresh();
    }

    return false if not defined $response->{'access_token'};

    print Dumper($response);

    $this->{'access_token'}   = $response->{'access_token'};
    $this->{'refresh_token'}  = $response->{'refresh_token'}; 
    $this->{'exiration_time'} = DateTime->now;

    $this->{'lwp_user_agent'}->default_header('Authorization' => "Bearer $this->{'access_token'}");

    return 200;
}

sub get_auth_url {
    my $this = shift;
    return (ENDPOINT_URLS->{'OAUTH_AUTHORIZE'} . "?client_id=$this->{'client_id'}&response_type=$this->{'response_type'}");
}

#-----------------------------------
# Refresh access token
#-----------------------------------
sub refresh {
    my $this      = shift;

    my $post_data = {
        'refresh_token' => $this->{'refresh_token'},
        'client_id'     => $this->{'client_id'},
        'client_secret' => $this->{'client_secret'},
        'grant_type'    => 'refresh_token'
    };

    my $response = $this->request(ENDPOINT_URLS->{'OAUTH_TOKEN'}, $post_data, 'POST');
       $response = decode_json($response) if length $response;

    print Dumper($response);

    my $expiration_datetime = DateTime->now;
       $expiration_datetime->add( hours => 1 );

    $this->{'refresh_token'}       = (defined $response->{'refresh_token'} &&
                                       length $response->{'refresh_token'} ? 
                                              $response->{'refresh_token'} : 
                                                  $this->{'refresh_token'});

    $this->{'access_token'}        = (defined $response->{'access_token'} &&
                                       length $response->{'access_token'} ? 
                                              $response->{'access_token'} : 
                                                  $this->{'access_token'});

    $this->{'expiration_datetime'} = (defined $response->{'expires_in'} && 
                                       length $response->{'expires_in'} ? $expiration_datetime :$this->{'expiration_datetime'});
                                             

    return (defined $this->{'data'}{'status'} ? $this->{'data'}{'status'} : 200);
}

#-----------------------------------
# API Request
#-----------------------------------
sub request {
    my ($this, $end_point, $data, $http_method, $response, $request) = @_;
    
    $http_method = lc($http_method);
    
    say $http_method;
    say Dumper($data);
    
    # Reset the last response code
    $this->{'last_response_code'} = undef;
    
    die("Error: request is empty.\n") if ! length $end_point;
    
    if($http_method eq 'post') {
        $response = $this->{'lwp_user_agent'}->post($end_point, $data);
    }
    elsif($http_method =~ m/^(?:get|delete)$/) {
        # If $data is a hash, let $query_string be empty.
        # If $data isn't a hash, let $query_string be set
        # to it. We do this because query strings and URIs
        # will be passed in as $data. When that happens, we
        # don't want to try iterating over it.
        my $query_string = ((ref($data) eq 'HASH') ? '' : $data);
        
        if(! length $query_string) {
            keys %$data;
            
            # Loop through the data hash and
            # build a query string from its keys
            # and values.
            while(my($key, $value) = each(%$data)) {
                $query_string .= (length $query_string ? '&' : '?');
                $query_string .= '&' unless ! length $query_string;
                $query_string .= "$key=$value";
            }
            
            $query_string .= '&_method=delete' if $http_method eq 'delete';
            $query_string .= '&_format=xml'    if $this->{'response_type'} eq 'xml';
        }
        
        say "Request: $end_point$query_string";
        
        # Fire!
        $request  = new HTTP::Request(GET => "$end_point$query_string");
        $response = $this->{'lwp_user_agent'}->request($request);
        
        $this->{'x_ratelimit_userlimit'}      = $response->{'_headers'}{'x-ratelimit-userlimit'};
        $this->{'x_ratelimit_userremaining'}  = $response->{'_headers'}{'x-ratelimit-userremaining'};
        $this->{'x_ratelimit_userreset'}      = $response->{'_headers'}{'x-ratelimit-userreset'};
        $this->{'x_ratelimit_clientlimit'}    = $response->{'_headers'}{'x-ratelimit-clientlimit'};
        $this->{'x_ratelimit_lientremaining'} = $response->{'_headers'}{'x-ratelimit-clientremaining'};
        
        print Dumper($response);
    }
    
    # If there's a response code and the response code
    # is a valid one, set $this->{'last_response_code'}
    # equal to it.
    if(defined $response->{'_rc'} && $response->{'_rc'} =~ m/^(200|400|401|403|404|429|500)$/) {
        $this->{'last_response_code'} = $1;
    }
    
    return ($this->{'full_response'} ? $response : $response->{'_content'});
}

#-----------------------------------
# Validation
#-----------------------------------
sub validate_username {
    my ($this, $username) = @_;
    die("Error: you must provide a username.\n")                        if (!defined $username || !length $username);
    die("Error: username must be atleast 4 alphanumeric characters.\n") if (length $username < 4);
    die("Error: username can only contain alphanumeric characters.\n")  if ($username =~ m/[^a-zA-Z0-9]/);
}

sub validate_id {
    my ($this, $id) = @_;
    die("Error: id must be a number.\n") unless $id =~ m/^(\d+)$/;
}

sub validate_page {
    my ($this, $page) = @_;
    die("Error: invalid page name.\n") unless $page =~ m/^(\d+)$/;
}

#-----------------------------------
# Setters
#-----------------------------------
sub set_response_type {
    my ($this, $response_type) = @_;
    
    die("Error: invalid response type.\n") 
        unless ($response_type =~ m/^(?:xml|json)$/i);

    $this->{'response_type'} = lc($response_type);
}

sub set_state {
    my ($this, $state)   = @_;
        $this->{'state'} = $state; 
}

sub set_pin {
    my $this = shift;
       $this->{'pin'} = shift;
}

sub set_refresh_token {
    my $this = shift;
       $this->{'refresh_token'} = shift;
}

sub set_expiration_datetime {
    my $this = shift;
       $this->{'expiration_datetime'} = shift;
}

sub set_no_auth {
    my $this = shift;
       $this->{'auth'} = 0;
}

#-------------------------------------
# Getters
#-------------------------------------
sub get_response_code {
        my $this = shift;
    return $this->{'last_response_code'};
}

sub get_access_token {
        my $this = shift;
    return $this->{'access_token'};
}

sub get_refresh_token {
        my $this = shift;
    return $this->{'refresh_token'};
}

sub get_expiration_datetime {
        my $this = shift;
    return $this->{'expiration_datetime'};
}

sub get_x_ratelimit_userlimit {
        my $this = shift;
    return $this->{'x_ratelimit_userlimit'};
}

sub get_x_ratelimit_userremaining {
        my $this = shift;
    return $this->{'x_ratelimit_userremaining'};
}

sub get_x_ratelimit_userreset {
        my $this = shift;
    return $this->{'x_ratelimit_userreset'};
}

sub get_x_ratelimit_clientlimit {
        my $this = shift;
    return $this->{'x_ratelimit_clientlimit'};
}

sub get_x_ratelimit_clientremaining {
        my $this = shift;
    return $this->{'x_ratelimit_clientremaining'};
}

#-----------------------------------
# Imgur getters
#-----------------------------------
sub get_account {
	my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username", 'GET');
}

sub get_gallery_favorites {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/gallery_favorites", 'GET');
}

sub get_account_favorites {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/favorites", 'GET');
}

sub get_account_submissions {
    my ($this, $username, $page) = @_;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/submissions/$page", 'GET');
}

sub get_account_settings {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/settings", 'GET');
}

sub send_verification_email {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/verifyemail", 'POST');
}

sub get_email_verification_status {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/verifyemail", 'POST');
}

sub get_account_albums {
    my ($this, $username, $page) = @_;
    $this->validate_username($username);
    $page ||= 0;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/albums/$page", 'GET');
}

sub get_account_album_ids {
    my ($this, $username, $page) = @_;
    $this->validate_username($username);
    $page ||= 0;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/ids/$page", 'GET');
}

sub get_account_album_count {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/albums/count", 'GET');
}

sub get_account_comments {
    my ($this, $username, $sort, $page) = @_;
    $this->validate_username($username);
    $sort ||= 'newest';
    $page ||= 0;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/comments/$sort/$page", 'GET');
}

sub get_account_comment_ids {
    my ($this, $username, $sort, $page) = @_;
    $this->validate_username($username);
    $sort ||= 'newest';
    $page ||= 0;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/comments/$sort/$page", 'GET');
}

sub get_account_comment_count {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/comments/count", 'GET');
}

sub get_album {
    my ($this, $album_id) = @_;
    die("Error: invalid album id.\n") unless $album_id =~ /^(?:\d+)$/;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/album/$album_id", 'GET');
}

sub get_comment {
    my ($this, $comment_id) = @_;
    die("Error: invalid comment id.\n") unless $comment_id =~ /^(?:\d+)$/;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/comment/$comment_id", 'GET');
}

# TODO: 
sub get_conversation {
    my ($this, $id, $page, $offset) = @_;
    
}

# TODO: 
sub get_custom_gallery {
    
}

sub get_gallery_album {
    my ($this, $gallery_album_id) = @_;
    die("Error: invalid gallery album id.\n") unless $gallery_album_id =~ /^(?:\d+)$/;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/gallery/album/$gallery_album_id", 'GET');
}

sub get_gallery_image {
    my ($this, $gallery_image_id) = @_;
    die("Error: invalid gallery image id.\n") unless $gallery_image_id =~ /^(?:\d+)$/;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/gallery/image/$gallery_image_id", 'GET');
}

sub get_gallery_profile {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/gallery_profile", 'GET');
}

sub get_image {
    my ($this, $image_id) = @_;
    die("Error: invalid image id.\n") unless $image_id =~ /^(?:\d+)$/;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/image/$image_id", 'GET');
}

# TODO:
sub get_meme_metadata {
    my $this = shift;
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/g/", 'GET');
}

sub get_notifications {
    my ($this, $username) = @_;
    $this->validate_username($username);
    return $this->request(ENDPOINT_URLS->{'IMGUR'}, "/account/$username/notifications", 'GET');
}


1;
