package WebService::SendBird;

use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::URL;

use WebService::SendBird::User;
use WebService::SendBird::GroupChat;

use Carp qw();


use constant DEFAULT_API_URL_TEMPLATE => 'https://api-%s.sendbird.com/v3';

sub new {
    my ($cls, %params) = @_;

    Carp::croak('api_token is missed') unless $params{api_token};
    Carp::croak('app_id or api_url is missed') unless $params{app_id} || $params{api_url};

    my $self = +{
        api_token => $params{api_token},
        $params{app_id} ? (app_id => $params{app_id}) : (),
        $params{api_url} ? (api_url => Mojo::URL->new($params{api_url})) : (),
    };

    return bless $self, $cls;
}

sub api_url {
    my $self = shift;

    $self->{api_url} //= Mojo::URL->new(sprintf(DEFAULT_API_URL_TEMPLATE, $self->{app_id}));

    return $self->{api_url};
}

sub ua {
    my $self = shift;

    $self->{ua} //= Mojo::UserAgent->new();

    return $self->{ua};
}

sub http_headers {
    my $self = shift;

    return {
        'Content-Type' => 'application/json, charset=utf8',
        'Api-Token'    => $self->{api_token},
    }
}



sub request {
    my ($self, $method, $path, $params) = @_;

    my $resp = $self->ua->start(
        $self->ua->build_tx(
            $method,
            $self->_url_for($path),
            $self->http_headers,
            uc($method) eq 'GET' ? (form => $params) : (json => $params),
        )
    );

    Carp::croak('Fail to make request to SB API') if $resp->result->code !~ /^2\d+/;

    my $data = $resp->result->json;

    Carp::croak('Fail to make request to SB API: ' . $data->{message}) if $data->{error};

    return $data;
}

sub _url_for {
    my ($self, $path) = @_;

    return join q{/} => ($self->api_url, $path);
}

sub create_user {
    my ($self, %params) = @_;

    Carp::Croak('profile_url is missed') unless exists $params{profile_url};
    $params{$_} or Carp::Croak('profile_url is missed') for (qw(user_id nickname));

    my $resp = $self->request(POST => 'users', \%params);

    return WebService::SendBird::User->new(%$resp, api_client => $self);
}


sub view_user {
    my ($self, %params) = @_;

    my $user_id = delete $params{user_id} or Carp::croak('user_is is missed');

    my $resp = $self->request(GET => "users/$user_id", \%params);

    return WebService::SendBird::User->new(%$resp, api_client => $self);
}


sub create_group_chat {
    my ($self, %params) = @_;

    my $resp = $self->request(POST => "group_channels", \%params);

    return WebService::SendBird::GroupChat->new(%$resp, api_client => $self);
}

sub view_group_chat {
    my ($self, %params) = @_;
    my $channel_url = delete $params{channel_url} or Carp::croak('channel_url is missed');

    my $resp = $self->request(GET => "group_channels/$channel_url", \%params);

    return WebService::SendBird::GroupChat->new(%$resp, api_client => $self);
}


1;
