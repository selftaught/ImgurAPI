# ImgurAPI perl library

ImgurAPI::Client is an Imgur API client module.

## Installation

### CPAN/M

`cpan ImgurAPI::Client`
or
`cpanm ImgurAPI::Client`

### Manual

1. Clone the repository `git clone https://github.com/selftaught/ImgurAPI.git`
2. Cd into the repo root and generate a makefile: `perl Makefile.pl`
3. Make it: `make && make test && make install`

## Usage

### Instantiation

```perl
my $client = ImgurAPI::Client->new( \%options );
```

Valid options are to pass into the constructor are:

- `client_id` - client identifier. used for authorization, refresh token requests and unauthenticated requests
- `client_secret` - client secret used for acquiring a refresh token
- `access_key` - used to authenticate requests
- `rapidapi_key` - commercial use api key
- `format_type` - api endpoint response format type. valid values are `json` (default) and `xml`
- `oauth_cb_state` - parameter appended to oauth2 authorization url returned from `oauth2_authorize_url()` which may be useful to your application upon receipt of the response.

You can also set the values using the setter member subroutines listed at the bottom of the page.

### Authorization

If you haven't already, register an application for an OAuth2 client ID and secret [here](https://api.imgur.com/oauth2/addclient).

You will need to authorize your OAuth2 application if you haven't already done so. You can get the authorization URL with `oauth2_authorize_url`:

```perl
my $auth_url = $client->oauth2_authorize_url();

# return to user's browser for manual authorization
```

### Authentication
Once the application has been authorized, the access token, refresh token and expires_in values will be passed to the callback endpoint URL that was specified during application registration. The callback endpoint should collect the values and store them somewhere your code on the backend can pull the access token from and then pass it to the client.

```perl
my $access_token = get_access_token_from_some_db();

$client->set_access_token($access_token);
```

The client library doesn't handle refreshing the access token for you automatically. It is left up to the calling code to refresh the access token when it expires. This is so you can keep the refresh token updated in the database you stored it in initially. The client library is unaware of the database so we leave it up to you to manage.

### Requests

## Imgur API endpoint subroutines

### Account

- `account($username)` - get information about an account
  - `$username` - string - imgur account username
- `account_album($username, $album_id)` - get information about an account album
  - `$username` - string - imgur account username
  - `$album_id` - int|string - album id
- `account_album_count($username)` - get the count of account albums
  - `$username` - string - imgur account username
- `account_album_delete($username, $album_id)` - delete an account album
  - `$username` - string - imgur account username
  - `$album_id` - int|string - album id
- `account_album_ids($username, \%optional)` - get a list of account album ids
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional parameters
    - `page` - int|str - page number
- `account_albums($username, \%optional)` - list account albums
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional parameters
    - `page` - int|str - page number
- `account_block_create($username)` - block a user
  - `$username` - string - imgur account username to block
- `account_block_status($username)` - determine if the user making the request has blocked a username
  - `$username` - string - imgur account username to check if is blocked
- `account_blocks()` - list all accounts being blocked by the requesting account
- `account_comment($username, $comment_id)` - get information about a comment
  - `$username` - string - imgur account username
  - `$comment_id` - string - comment id
- `account_comment_count($username)`
  - `$username` - string - imgur account username
- `account_comment_delete($username, $comment_id)`
  - `$username` - string - imgur account username
  - `$comment_id` - string - comment id
- `account_comment_ids($username, \%optional)`
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional parameters
    - `page` - int|string - page number
    - `sort` - string - best, worst, oldest or newest (default)
- `account_comments($username, \%optional)`
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional parameters
    - `page` - int|string - page number
    - `sort` - string - best, worst, oldest or newest (default)
- `account_delete($password, \%optional)`
  - `$password` - string - imgur account password
  - `\%optional` - hashref - hashref of optional params
    - `reasons` - arrayref of strings - reasons for deleting account
    - `feedback` - string - feedback for imgur
- `account_favorites($username, \%optional)`
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional params
    - `page` - int|string - page number (default: 0)
    - `sort` - string - oldest or newest (default)
- `account_tag_follow($tag_name)`
  - `$tag_name` - string - tag to follow
- `account_tag_unfollow($tag_name)`
  - `$tag_name` - string - tag to unfollow
- `account_gallery_favorites($username, \%optional)`
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional params
    - `page` - int|string - page number (default: 0)
    - `sort` - string - oldest or newest (default)
- `account_image($username, $image_id)` - get info about an image
  - `$username` - string - imgur account username
  - `$image_id` - string - image id to get information about
- `account_image_count($username)`
  - `$username` - string - imgur account username
- `account_image_delete($username, $image_id)` - delete an image
  - `$username` - string - imgur account username
  - `$image_id` - string - image id to delete
- `account_image_ids($username, \%optional)`
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional params
    - `page` - int|string - page number (default: 0)
- `account_images($username, \%optional)`
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional params
    - `page` - int|string - page number (default: 0)
- `account_reply_notifications($username, new)`
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional params
    - `new` - int|boolean - 1 for unviewed notification and 0 for viewed (default: 1)
- `account_settings($username)`
  - `$username` - string - imgur account username
- `account_settings_update($username, \%settings)`
  - `$username` - string - imgur account username
  - `\%settings` - hashref - hashref of settings to update
    - `bio` - string - biography displayed on the account
    - `public_images` - int|boolean - set images to private or public by default
    - `messaging_enabled` - int|boolean - enable / disable private messages
    - `accepted_gallery_terms` - int|boolean - user agreement to imgur gallery terms
    - `username` - string - valid username between 4 and 63 alphanumeric characters
    - `show_mature` - int|boolean - toggle display of mature content
    - `newsletter_subscribed` - int|boolean - toggle subscription to email newsletter
- `account_submissions($username, \%optional)`
  - `$username` - string - imgur account username
  - `\%optional` - hashref - hashref of optional params
    - `page` - int|string - page number (default: 0)
- `account_verify_email_send($username)`
  - `$username` - string - imgur account username
- `account_verify_email_status($username)`
  - `$username` - string - imgur account username

### Album

- `album($album_id)`
  - `$album_id` - string
- `album_images($album_id)`
  - `$album_id` - string
- `album_create(\%options)`
  - `\%options`
    - `ids` - arrayref
    - `deletehashes` - arrayref
    - `title` - string
    - `description` - string
    - `cover` - string
- `album_update($album_id, \%options)`
  - `$album_id` - string
  - `\%options`
    - `ids` - arrayref
    - `deletehashes` - arrayref
    - `title` - string
    - `description` - string
    - `cover` - string
- `album_delete($album_id)`
  - `$album_id` - string
- `album_favorite($album_id)`
  - `$album_id` - string
- `album_images_set($album_id, \@ids)`
  - `$album_id` - string
  - `\@ids` - arrayref
- `album_images_add($album_id, \@ids)`
  - `$album_id` - string
  - `\@ids` - arrayref
- `album_images_delete($album_id, \@ids)`
  - `$album_id` - string
  - `\@ids` - arrayref

### Comment

- `comment($comment_id)` - get comment info
  - `$comment_id` - string
- `comment_delete($comment_id)`
  - `$comment_id` - string
- `comment_replies($comment_id)`
  - `$comment_id` - string
- `comment_reply($comment_id, $image_id, $comment)`
  - `$comment_id` - string
- `comment_vote($comment_id, $vote)`
  - `$comment_id` - string
  - `$vote` - string - can be 'up', 'down' or 'veto'
- `comment_report($comment_id)`
  - `$comment_id` - string

### Gallery

- `gallery(\%optional)`
  - optional:
    - `section` - hot (default), top, user
    - `sort` - viral (default), top, time, rising
    - `page` - page number
    - `window` - day (default), week, month, year, all
    - `show_viral` - 0 or 1 (default)
    - `album_preview` - 0 or 1 (default)
- `gallery_album($album_id)`
- `gallery_image($image_id)`
- `gallery_image_remove($image_id)`
- `gallery_item($id)`
- `gallery_item_comment($id, $comment)`
- `gallery_item_comment_info($id, $comment_id)`
- `gallery_item_comments($id, \%optional)`
  - optional:
    - `sort` - one of: best (default), top, or new
- `gallery_item_report($id, \%optional)`
  - optional:
    - `reason` - integer value reason for report. values:
      - `1` - doesn't belong on imgur
      - `2` - spam
      - `3` - abusive
      - `4` - mature content not marked as mature
      - `5` - pornography
- `gallery_item_tags_update($id, \@tags)`
- `gallery_item_vote($id, $vote)`
  - `vote` - up, down, or veto
- `gallery_item_votes($id)`
- `gallery_item_tags($id)`
- `gallery_search($query, \%optional, \%advanced)`
  - optional:
    - `sort` - viral, top, time (default), rising
    - `page` - page number (default: 0)
    - `window` - day, week, month, year, all (default)
  - advanced (note: if advanced search parameters are set, query string is ignored):
    - `q_all` - search for all of these words (and)
    - `q_any` - search for any of these words (or)
    - `q_exactly` - search for exactly this word or phrase
    - `q_not` - exclude results matching this
    - `q_type` - show results for file type (jpg, png, gif, anigif, album)
    - `q_size_pix` - size ranges, small (500 pixels square or less) | med (500 to 2,000 pixels square) | big (2,000 to 5,000 pixels square) | lrg (5,000 to 10,000 pixels square) | huge (10,000 square pixels and above)
- `gallery_share_image($id, $title, \%optional)`
  - optional:
    - `topic` - topic name
    - `terms` - if the user has not accepted the terms yet, this endpoint will return an error. pass `1` to by-pass
    - `mature` - set to `1` if the post is mature
    - `tags` - The name of the tags you wish to associate with a post. Can be passed as an array or csv string
- `gallery_share_album($id, $title, \%optional)`
  - optional:
    - `topic` - topic name
    - `terms` - if the user has not accepted the terms yet, this endpoint will return an error. pass `1` to by-pass
    - `mature` - set to `1` if the post is mature
    - `tags` - The name of the tags you wish to associate with a post. Can be passed as an array or csv string
- `gallery_subreddit($subreddit, \%optional)`
  - optional:
    - `sort` - viral (default), top, time, rising
    - `page` - page number (default: 0)
    - `window` - day, week (default), month, year, all
- `gallery_subreddit_image($subreddit, $image_id)`
- `gallery_tag($tag, \%optional)`
  - optional:
    - `sort` - viral (default), top, time, rising
    - `page` - page number (default: 0)
    - `window` - day, week (default), month, year, all
- `gallery_tag_info($tag)`
- `gallery_tags()`

### Image

- `image($image_id)`
- `image_upload($src, \%optional)`
  - `src` image or video source - can be one of type: file, url, base64 or raw string
  - `type` image or video source type - can be one of: file, url, base64 or raw string
  - `optional` optional data can include
    - `title` - title of the content
    - `description` - description of the content
- `image_delete($image_id)`
- `image_favorite($image_id)`
- `image_update($image_id, \%optional)`
  - optional:
    - `title` - content title
    - `description` - content description

### Feed

- `feed()`

## Client member sub-routines

### Getters

- `response()`
- `response_content()`
- `access_token()`
- `ratelimit_headers()`
  - returns rate limit key value pairs from imgur api response:
    - `userlimit`
    - `userremaining`
    - `userreset`
    - `clientlimit`
    - `clientremaining`

### Setters

- `set_state(state)`
- `set_access_token(access_token)`
- `set_refresh_token(refresh_token)`
- `set_expiration_datetime(datetime)`
- `set_no_auth()`
