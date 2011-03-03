package EWS::Messages::Role::Sender;
BEGIN {
  $EWS::Messages::Role::Sender::VERSION = '1.103620';
}
use Moose::Role;

use Carp;

sub _list_messages {
    my ($self, $kind, $response) = @_;
    return @{ $response->{"${kind}Result"}
                       ->{ResponseMessages}
                       ->{cho_CreateItemResponseMessage} };
}

sub _check_for_errors {
    my ($self, $kind, $response) = @_;

    foreach my $msg ( $self->_list_messages($kind, $response) ) {
        my $code = $msg->{"${kind}ResponseMessage"}->{ResponseCode} || '';
        croak "Fault returned from Exchange Server: $code\n"
            if $code ne 'NoError';
    }
}

# Creates and sends an item.  Cannot send an existing item (yet)
# Options:
#   no_saved_copy => true causes the server to not put a copy of the message
#     in your sent items folder
sub send {
    my ($self, $messages, $opts) = @_;

    $messages = [ $messages ] unless ref $messages eq 'ARRAY';

    # two different calls are required, CreateItem for new messages, and
    # SendItem if the message already exists on the server (eg. in Drafts).
    # The differentiating factor is the existence of an ItemId field
    my (@to_create, @to_send);

    foreach my $message (@$messages) {
        if ($message->has_ItemId) {
            push(@to_send, $message);
        } else {
            push(@to_create, $message);
        }
    }

    my $create_response = $self->client->CreateItems(\@to_create, { 
            (exists $opts->{impersonate} ? ( 
                impersonate => $opts->{impersonate} 
            ) : ()),
            action => (exists $opts->{no_saved_copy} && $opts->{no_saved_copy} ? 
                "SendOnly" : "SendAndSaveCopy"),
        }
    );

    # XXX the error checking routines need to be significantly enhanced.
    # Notably, they need to take into account the fact that creating one item
    # may have failed where the rest of the creations succeeded, and they
    # should expose all of the (gasp!) useful information that the errors
    # provide
    $self->_check_for_errors('CreateItem', $create_response);

    # XXX need to handle the already existing messages that languish in
    # @to_send
}

no Moose::Role;
1;
