# perl-WebService-SendBird

Synchronous API support for the SendBird messaging service.

Documentation for SendBird platform API could be found at [here](https://docs.sendbird.com/platform)

# Usage

```
use WebService::SendBird;

my $api = WebService::SendBird->new(
    api_token => 'You_Api_Token_Here',
    app_id    => 'You_App_ID_Here',
);

my $user = $api->create_user(
    user_id     => 'my_chat_user_1',
    nickname    => 'pumpkin',
    profile_url => undef,
)

my $chat = $api->create_group_chat(
    user_ids => [ $user->user_id ],
);
```


