# ImgurAPI perl library

ImgurAPI is a perl5 client library for interfacing with Imgur's API endpoints.

## Installation

1. Clone the repository `git clone https://github.com/selftaught/ImgurAPI.git`
2. Cd into the repo root and generate a makefile: `perl Makefile.pl`
3. Make it: `make && make test && make install`

## Usage

### Instantiating the client

```perl
my $client = ImgurAPI->new( \%options );
```

Valid options are:

_note that all are optional but the library will throw if its needed and not defined_

- `client_id`
- `client_secret`
- `access_key`
- `rapidapi_key`
  - commercial rapidapi / mashape api key (commercial use)
- `format_type`
  - api endpoint response format type
  - valid values are `json` (default) and `xml`
- `oauth_cb_state`
  - parameter appended to oauth2 authorization url returned from `get_oauth2_url()` which may be useful to your application upon receipt of the response.

### Authorization

If you haven't already, register an application for an OAuth2 client ID and secret [here](https://api.imgur.com/oauth2/addclient).

You will need to authorize your OAuth2 application if you haven't already done so. You can get the authorization URL with `get_oauth2_url`:

```perl
my $auth_url = $client->get_oauth2_url();

# return to user's browser for manual authorization
```

Once the application has been authorized, the access token, refresh token and expires_in values will be passed to the callback endpoint URL that was specified during application registration. The callback endpoint should collect the values and store them somewhere your client calling code on the backend can pull the access token from and then pass it to the client.

```perl
my $access_token = get_access_token_from_some_db();

$client->set_access_token($access_token);
```

The client library doesn't handle refreshing the access token for you automatically. It is left up to the calling code to refresh the access token when it expires. This is so you can keep the refresh token updated in the database you stored it in initially. The client library is unaware of the database so we leave it up to you to manage.

### Requests

## Imgur API endpoint subroutines

### Account

- `account(username)`
- `account_album_count(username)`
- `account_album_count(username)`
- `account_album_ids(username, page)`
- `account_albums(username, page)`
- `account_block_create(username)`
- `account_block_status(username)`
- `account_blocks(username)`
- `account_comment(username, id)`
- `account_comment_count(username)`
- `account_comment_delete(username, id)`
- `account_comment_ids(username, sort, page)`
- `account_comments(username, sort, page)`
- `account_delete(client_id, body)`
- `account_favorites(username)`
- `account_tag_follow(tag_name)`
- `account_tag_unfollow(tag_name)`
- `account_gallery_favorites(username, page, sort)`
- `account_image(username, id)`
- `account_image_delete(username, id)`
- `account_image_ids(username, page)`
- `account_images(username, page)`
- `account_images(username)`
- `account_reply_notifications(username, new)`
- `account_settings(username)`
- `account_settings_update(username, fields)`
- `account_submissions(username, page)`
- `account_tag_unfollow(tag_name)`
- `account_verify_email_send(username)`
- `account_verify_email_status(username)`

### Album

- `album(album_id)`
- `album_images(album_id)`
- `album_create(fields)`
- `album_update(album_id, fields)`
- `album_delete(album_id)`
- `album_favorite(album_id)`
- `album_set_images(album_id, ids)`
- `album_add_images(album_id, ids)`
- `album_delete_images(album_id, ids)`

### Comment

- `comment(comment_id)`
- `comment_delete(comment_id)`
- `comment_replies(comment_id)`
- `comment_reply(comment_id, image_id, comment)`
- `comment_vote(comment_id, vote='up')`
- `comment_report(comment_id)`

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
- `gallery_tag_vote(item_id, tag, vote)`
- `gallery_tags()`

### Image

- `image($id)`
- `image_upload($src, \%optional)`
  - `src` image or video source - can be one of type: file, url, base64 or raw string
  - `type` image or video source type - can be one of: file, url, base64 or raw string
  - `optional` optional data can include
    - `title` - title of the content
    - `description` - description of the content
- `image_delete($id)`
- `image_favorite($id)`

### Feed

- `feed()`

## Client member sub-routines

### Getters

- `get_response()`
- `get_response_content()`
- `get_access_token()`
- `get_x_ratelimit_userlimit()`
- `get_x_ratelimit_userremaining()`
- `get_x_ratelimit_userreset()`
- `get_x_ratelimit_clientlimit()`
- `get_x_ratelimit_clientremaining()`

### Setters

- `set_state(state)`
- `set_access_token(access_token)`
- `set_refresh_token(refresh_token)`
- `set_expiration_datetime(datetime)`
- `set_no_auth()`

## TODO

- [ ] ETag support for performance
- [ ] Core library tests
- [ ] Publish to CPAN/METACPAN
- [ ] Public API requests (using only client_id and client_secret)