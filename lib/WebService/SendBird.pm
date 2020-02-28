package WebService::SendBird;

use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::URL;

use WebService::SendBird::User;
use WebService::SendBird::GroupChat;

use Carp qw();

our $VERSION = '0.001';

# ABSTRACT: Webservice to connect to SendBird API

=head1 NAME
WebService::SendBird - unofficial support for the Sendbird Api
=head1 SYNOPSIS
=head1 DESCRIPTION
=cut

use constant DEFAULT_API_URL_TEMPLATE => 'https://api-%s.sendbird.com/v3';


=head2 new

=cut

sub new {
    my ($cls, %params) = @_;

    Carp::croak('Missing required argument: api_token') unless $params{api_token};
    Carp::croak('Missing required argument: app_id or api_url') unless $params{app_id} || $params{api_url};

    my $self = +{
        api_token => $params{api_token},
        $params{app_id}  ? (app_id  => $params{app_id})                  : (),
        $params{api_url} ? (api_url => Mojo::URL->new($params{api_url})) : (),
        $params{ua}      ? (ua      => $params{ua})                      : (),
    };

    return bless $self, $cls;
}


=head2 app_id

=cut

sub app_id { shift->{app_id} }

=head2 api_token

=cut

sub api_token { shift->{api_token} }

=head2 api_url

=cut

sub api_url {
    my $self = shift;

    $self->{api_url} //= Mojo::URL->new(sprintf(DEFAULT_API_URL_TEMPLATE, $self->app_id));

    return $self->{api_url};
}

=head2 ua

=cut

sub ua {
    my $self = shift;
    #TODO Need to add configuration to user agent
    $self->{ua} //= Mojo::UserAgent->new();

    return $self->{ua};
}

=head2 http_headers

=cut

sub http_headers {
    my $self = shift;

    return {
        'Content-Type' => 'application/json, charset=utf8',
        'Api-Token'    => $self->api_token,
    }
}


=head2 request

=cut

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
    #TODO Improve error handling
    Carp::croak('Fail to make request to SB API') if $resp->result->code !~ /^2\d+/;

    my $data = $resp->result->json;

    Carp::croak('Fail to make request to SB API: ' . $data->{message}) if $data->{error};

    return $data;
}

=head2 create_user

=cut

sub create_user {
    my ($self, %params) = @_;

    Carp::croak('profile_url is missed') unless exists $params{profile_url};
    $params{$_} or Carp::croak("$_ is missed") for (qw(user_id nickname));

    my $resp = $self->request(POST => 'users', \%params);

    return WebService::SendBird::User->new(%$resp, api_client => $self);
}


=head2 view_user

=cut

sub view_user {
    my ($self, %params) = @_;

    my $user_id = delete $params{user_id} or Carp::croak('user_id is missed');

    my $resp = $self->request(GET => "users/$user_id", \%params);

    return WebService::SendBird::User->new(%$resp, api_client => $self);
}

=head2 create_group_chat

=cut

sub create_group_chat {
    my ($self, %params) = @_;

    my $resp = $self->request(POST => "group_channels", \%params);

    return WebService::SendBird::GroupChat->new(%$resp, api_client => $self);
}


=head2 view_group_chat

=cut

sub view_group_chat {
    my ($self, %params) = @_;
    my $channel_url = delete $params{channel_url} or Carp::croak('channel_url is missed');

    my $resp = $self->request(GET => "group_channels/$channel_url", \%params);

    return WebService::SendBird::GroupChat->new(%$resp, api_client => $self);
}

sub _url_for {
    my ($self, $path) = @_;

    return join q{/} => ($self->api_url, $path);
}


1;
