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
- `mashape_key`
  - commercial rapidapi api key
- `format_type`
  - api endpoint response format type
  - valid values are `json` (default) and `xml`
- `oauth_state`
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

- `gallery(section='hot', sort, page, window='day', show_viral=True)`
- `gallery_subreddit(subreddit, sort, window='week', page)`
- `gallery_subreddit_image(subreddit, image_id)`
- `gallery_tag(tag, sort, page, window='week')`
- `gallery_tag_image(tag, item_id)`
- `gallery_item_tags(item_id)`
- `gallery_tag_vote(item_id, tag, vote)`
- `gallery_search(q, advanced=None, sort, window='all', page)`
- `gallery_random(page)`
- `gallery_share_image(image_hash, title, terms=0)`
- `gallery_share_album(album_hash)`
- `gallery_remove(gallery_hash)`
- `gallery_item(item_id)`
- `gallery_item_vote(item_id, vote='up')`
- `gallery_item_comments(item_id, sort)`
- `gallery_comment(item_id, comment)`
- `gallery_comment_ids(item_id)`
- `gallery_comment_count(item_id)`

### Image

- `image(image_id)`
- `image_upload_from_path(path, config=None, anon=True)`
- `image_upload_from_url(url, config=None, anon=True)`
- `image_delete(image_id)`
- `image_favorite(image_id)`

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
- [ ] Account endpoint tests
- [ ] Album endpoint tests
- [ ] Comment endpoint tests
- [ ] Gallery endpoint tests
- [ ] Image endpoint tests
- [ ] Feed endpoint tests
- [ ] Publish to CPAN/METACPAN
- [ ] Public API requests (using only client_id and client_secret)