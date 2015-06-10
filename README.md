## NOTE: THIS MODULE IS NOT YET COMPLETE!

## ImgurAPI

ImgurAPI is a module which wraps around and abstracts Imgur's API using Perl5. 

## Installation

### Manual 

1. Download the zip archive: `wget https://github.com/selftaught/ImgurAPI/archive/master.zip`
2. Unzip it: `unzip master.zip`
3. Run Makefile.pl to create a makefile: `perl Makefile.pl`
4. Make it: `make && make test && make install`

### Install script

Coming soon...

### CPAN

Coming soon... 

## Examples

Can be found [here](https://github.com/selftaught/ImgurAPI/examples).

## Threading

This module is currently NOT thread safe.

## Imgur Specific Subroutines

### Account

- `get_account(username)`
- `get_gallery_favorites(username)`
- `get_account_favorites(username)`
- `get_account_submissions(username, page=0)`
- `get_account_settings(username)`
- `get_email_verification_status(username)`
- `send_verification_email(username)`
- `get_account_albums(username, page=0)`
- `get_account_album_ids(username, page=0)`
- `get_account_album_count(username)`
- `get_account_comments(username, sort='newest', page=0)`
- `get_account_comment_ids(username, sort='newest', page=0)`
- `get_account_comment_count(username)`
- `get_account_images(username, page=0)`
- `get_account_image_ids(username, page=0)`
- `get_account_album_count(username)`
- `change_account_settings(username, fields)`

### Album

- `get_album(album_id)`
- `get_album_images(album_id)`
- `create_album(fields)`
- `update_album(album_id, fields)`
- `album_delete(album_id)`
- `album_favorite(album_id)`
- `album_set_images(album_id, ids)`
- `album_add_images(album_id, ids)`
- `album_remove_images(album_id, ids)`

### Comment

- `get_comment(comment_id)`
- `delete_comment(comment_id)`
- `get_comment_replies(comment_id)`
- `post_comment_reply(comment_id, image_id, comment)`
- `comment_vote(comment_id, vote='up')`
- `comment_report(comment_id)`

### Custom Gallery

- `get_custom_gallery(gallery_id, sort='viral', window='week', page=0)`
- `get_user_galleries()`
- `create_custom_gallery(name, tags=None)`
- `custom_gallery_update(gallery_id, name)`
- `custom_gallery_add_tags(gallery_id, tags)`
- `custom_gallery_remove_tags(gallery_id, tags)`
- `custom_gallery_delete(gallery_id)`
- `filtered_out_tags()`
- `block_tag(tag)`
- `unblock_tag(tag)`

### Gallery

- `gallery(section='hot', sort='viral', page=0, window='day', show_viral=True)`
- `memes_subgallery(sort='viral', page=0, window='week')`
- `memes_subgallery_image(item_id)`
- `subreddit_gallery(subreddit, sort='time', window='week', page=0)`
- `subreddit_image(subreddit, image_id)`
- `gallery_tag(tag, sort='viral', page=0, window='week')`
- `gallery_tag_image(tag, item_id)`
- `gallery_item_tags(item_id)`
- `gallery_tag_vote(item_id, tag, vote)`
- `gallery_search(q, advanced=None, sort='time', window='all', page=0)`
- `gallery_random(page=0)`
- `share_on_imgur(item_id, title, terms=0)`
- `remove_from_gallery(item_id)`
- `gallery_item(item_id)`
- `report_gallery_item(item_id)`
- `gallery_item_vote(item_id, vote='up')`
- `gallery_item_comments(item_id, sort='best')`
- `gallery_comment(item_id, comment)`
- `gallery_comment_ids(item_id)`
- `gallery_comment_count(item_id)`

### Image

- `get_image(image_id)`
- `upload_from_path(path, config=None, anon=True)`
- `upload_from_url(url, config=None, anon=True)`
- `delete_image(image_id)`
- `favorite_image(image_id)`

### Conversation

- `conversation_list()`
- `get_conversation(conversation_id, page=1, offset=0)`
- `create_message(recipient, body)`
- `delete_conversation(conversation_id)`
- `report_sender(username)`
- `block_sender(username)`

### Notification

- `get_notifications(new=True)`
- `get_notification(notification_id)`
- `mark_notifications_as_read(notification_ids)`

### Memegen

- `default_memes()`

## Wrapper Specific Subroutines

### Getters

- `get_response_code()`
- `get_access_token()`
- `get_refresh_token()`
- `get_expiration_datetime()`
- `get_x_ratelimit_userlimit()`
- `get_x_ratelimit_userremaining()`
- `get_x_ratelimit_userreset()`
- `get_x_ratelimit_clientlimit()`
- `get_x_ratelimit_clientremaining()`

#### Setters
 - `set_response_type(type)`
 - `set_state(state)`
 - `set_pin(pin)`
 - `set_refresh_token(token)`
 - `set_expiration_datetime(datetime)`
 - `set_no_auth()`
 

