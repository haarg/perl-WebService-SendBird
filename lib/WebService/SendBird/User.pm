package WebService::SendBird::User;

use strict;
use warnings;

use Carp;
use JSON::PP;

use constant REQUIRED_FIELDS => qw(
    api_client
    user_id
);

use constant OPTIONAL_FIELDS => qw(
    phone_number
    has_ever_logged_in
    session_tokens
    access_token
    discovery_keys
    is_online
    last_seen_at
    nickname
    profile_url
    metadata
);

{
    no strict 'refs';
    for my $field (REQUIRED_FIELDS, OPTIONAL_FIELDS) {
        *{ __PACKAGE__ . '::' . $field } = sub { shift->{$field} };
    }
}

sub new {
    my ($cls, %params) = @_;

    my $self = +{};
    $self->{$_} = delete $params{$_} or Carp::croak "$_ is missed" for (REQUIRED_FIELDS);

    $self->{$_} = delete $params{$_} for (OPTIONAL_FIELDS);

    return bless $self, $cls;
}

sub update {
    my ($self, %params) = @_;

    my $res = $self->api_client->request(PUT => 'users/' . $self->user_id, \%params);

    $self->{$_} = $res->{$_} for qw(OPTIONAL_FIELDS);

    return $self
}

sub issue_session_token {
    my ($self) = @_;

    $self->update(issue_session_token => $JSON::PP::true);

    my $tokens = $self->session_tokens // [];

    my ($latest_token) = sort { $b->{expires_at} <=> $a->{expires_at} } @$tokens;

    return $latest_token;
}

1;
