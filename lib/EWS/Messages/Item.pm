package EWS::Messages::Item;
BEGIN {
  $EWS::Messages::Item::VERSION = '1.103620';
}
use Moose;

use Moose::Util::TypeConstraints;

extends 'EWS::Client::Item';

has [qw(ConversationIndex ConversationTopic)] => (
    is => 'rw',
    isa => 'Str',
);

has From => (
    is => 'rw',
    isa => 'HashRef[Str]',
    traits => ['Hash'],
    handles => {
        FromAddress => [ accessor => 'EmailAddress' ],
        FromName => [ accessor => 'Name' ],
    },
);

has Sender => (
    is => 'rw',
    isa => 'HashRef[Str]',
    traits => ['Hash'],
    handles => {
        SenderAddress => [ accessor => 'EmailAddress' ],
        SenderName => [ accessor => 'Name' ],
    },
);

has InternetMessageId => (
    is => 'ro',
    isa => 'Str',
);

has [qw(IsDeliveryReceiptRequested IsReadReceiptRequested IsRead
        IsResponseRequested)] => (
    is => 'ro',
    isa => 'Bool',
);

has References => (
    is => 'rw',
    isa => 'Str',
);

# has ReplyTo

# has ToRecipients
# has CcRecipients
# has BccRecipients

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    $class->SUPER::BUILDARGS($params);

    # dig things out of deep structures
    $params->{From} = $params->{From}{Mailbox};
    $params->{Sender} = $params->{Sender}{Mailbox};

    return $params;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
