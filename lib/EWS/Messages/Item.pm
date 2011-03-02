package EWS::Messages::Item;
BEGIN {
  $EWS::Messages::Item::VERSION = '1.103620';
}
use Moose;
use Data::Dumper;

use Moose::Util::TypeConstraints;

extends 'EWS::Client::Item';

# see Client::Item for docs on this constant
use constant FIELDURI_NAMESPACE => 'message'; 

# EWS seems to barf if we set these (in CreateItem, anyway)
has [qw(ConversationIndex ConversationTopic)] => (
    is => 'rw',
    isa => 'Str',
#    traits => [qw(Serialized)],
);

has From => (
    is => 'rw',
    isa => 'HashRef[Str]',
    traits => [qw(Serialized)],
    serialization_helper => \&_create_address_struct,
);

has Sender => (
    is => 'rw',
    isa => 'HashRef[Str]',
    traits => [qw(Serialized)],
    serialization_helper => \&_create_address_struct,
);

has InternetMessageId => (
    is => 'ro',
    isa => 'Str',
#    traits => [qw(Serialized)],
);

has [qw(IsDeliveryReceiptRequested IsReadReceiptRequested IsRead
        IsResponseRequested)] => (
    is => 'rw',
    isa => 'Bool',
    traits => [qw(Serialized)],
);

has References => (
    is => 'rw',
    isa => 'Str',
    traits => [qw(Serialized)],
);

# lists of addressess
#   to, cc, bcc, and reply_to all do the obvious things.  They can be an 
#     individual string containing an email address, a hashref in the
#     following structure 
#        { name => 'display name', email_address => 'address' } 
#     or a list of those elements.  Yes, reply_to can be a list.
has [qw(ReplyTo ToRecipients CcRecipients BccRecipients)] => (
    is => 'rw',
    traits => [qw(Serialized)],
    serialization_helper => \&_create_address_struct,
);

sub _create_address_struct {
    my ($self, $addrs) = @_;

    return undef if not defined $addrs;
    $addrs = [ $addrs ] if ref $addrs ne 'ARRAY';

#    use Data::Dumper;
#    print Dumper $addrs;

    my $ret = { cho_Mailbox => [ ] };

    foreach my $addr (@$addrs) {
        next unless defined $addr;

        my $mailbox = { Mailbox => { } };

        if (ref $addr eq 'HASH') {
            # XXX hack alert for this next statement.  I can't figure out why
            # From and Sender seem to always have values despite not being
            # assigned to, so this traps the case and kicks out
            next if scalar keys %$addr eq 0;

            $mailbox->{Mailbox} = {
                (exists $addr->{EmailAddress} ? 
                    ( EmailAddress => $addr->{EmailAddress}, ) : ()),
                (exists $addr->{Name} ? 
                    ( Name => $addr->{Name}, ) : ()),
                (exists $addr->{RoutingType} ? 
                    ( RoutingType => $addr->{RoutingType}, ) : ()),
            };
        } else {
            $mailbox->{Mailbox} = { EmailAddress => $addr };
        }

        push(@{$ret->{cho_Mailbox}}, $mailbox);
    }

    return $ret if scalar @{$ret->{cho_Mailbox}} > 0;
    return undef;
}

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    $class->SUPER::BUILDARGS($params);

    # arrange for these messages to be called 'Message' instead of 'Item' when
    # sent to the server
    $params->{SerializationItemName} = 'Message';

    # as a temporary measure, assume that if there's no ItemId stanza in the
    #  data being used to build this object it's a user-created one.  We don't
    #  want to mangle the params for user-created objects.
    return $params unless exists $params->{ItemId};

    # dig things out of deep structures
    $params->{From} = $params->{From}{Mailbox}
        if defined $params->{From}{Mailbox};
    $params->{Sender} = $params->{Sender}{Mailbox}
        if defined $params->{Sender}{Mailbox};

    # process the arrays of mailbox structures into the format for input that
    # we accept
    foreach my $field (qw(ReplyTo ToRecipients CcRecipients BccRecipients)) {
        next unless defined $params->{$field};

        $params->{$field} = $params->{$field}{cho_Mailbox};

        foreach my $mailbox (@{$params->{$field}}) {
            $mailbox = $mailbox->{Mailbox};
        }
    }

    return $params;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
