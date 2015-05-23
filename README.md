## NOTE: THIS MODULE ISN'T COMPLETE!

## ImgurAPI
ImgurAPI is a module which wraps Imgur's API. 

## Installation

#### Manual 

1. Download the zip archive: `wget https://github.com/selftaught/PERL-ImgurAPI/archive/master.zip`
2. Unzip it: `unzip master.zip`
3. Run Makefile.pl to create a makefile: `perl Makefile.pl`
4. Make it: `make && make test && make install`

#### Install script

coming soon...

#### CPAN

coming soon... 

## Examples

## Imgur Specific Subroutines
#### Account
- `get_account(username)`
- `get_account_albums(username, page)`
- `get_account_settings(username)`
- `get_notifications(username)`
- `get_album(album_id)`
- `get_comment(comment_id)`
- `get_conversation(conversation_id)`
- `get_custom_gallery(gallery_id)`
- `get_gallery_album(album_id)`
- `get_gallery_image(image_id)`
- `get_gallery_profile(username)`
- `get_image(image_id)`

## Wrapper Specific Subroutines
#### Getters
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
 
