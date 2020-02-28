package WebService::SendBird::GroupChat;

use strict;
use warnings;

use Carp;
use WebService::SendBird::User;

=head1 NAME
WebService::SendBird::User
=head1 SYNOPSIS
=head1 DESCRIPTION
=cut

use constant REQUIRED_FIELDS => qw(
    api_client
    channel_url
);

use constant OPTIONAL_FIELDS => qw(
    is_broadcast
    name
    is_access_code_required
    is_super
    joined_member_count
    is_public
    cover_url
    unread_mention_count
    is_created
    is_distinct
    is_ephemeral
    freeze
    data
    is_discoverable
    last_message
    sms_fallback_interval_sec
    custom_type
    unread_message_count
    created_at
    member_count
    sms_fallback_enabled
    max_length_message
    members
);

{
    no strict 'refs';
    for my $field (REQUIRED_FIELDS, OPTIONAL_FIELDS) {
        *{ __PACKAGE__ . '::' . $field } = sub { shift->{$field} };
    }
}

=head2 new

=cut

sub new {
    my ($cls, %params) = @_;

    my $self = +{};
    $self->{$_} = delete $params{$_} or Carp::croak "$_ is missed" for (REQUIRED_FIELDS);

    $self->{$_} = delete $params{$_} for (OPTIONAL_FIELDS);

    $self->{members} //= [];
    my @obj_members = map { WebService::SendBird::User->new(%$_, api_client => $self->{api_client}) }  @{$self->{members}};
    $self->{members} = \@obj_members;

    return bless $self, $cls;
}

=head2 update

=cut

sub update {
    my ($self, %params) = @_;

    my $res = $self->api_client->request(PUT => 'group_channels/' . $self->channel_url, \%params);

    $self->{$_} = $res->{$_} for qw(OPTIONAL_FIELDS);

    return $self
}


1;
