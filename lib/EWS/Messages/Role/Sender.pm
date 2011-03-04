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

# Sends (and creates+sends if required) an item. Cannot specify where to save
# copies of sent messages (yet): they go to the default (Sent Items) folder.
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

    if (scalar @to_create) {
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

        # something like this code should probably be run as well, (possibly
        # in the CreateItems function) for the times where the items are
        # created and only saved (that's the only case where the ItemId is
        # actually returned, when a message is sent, more complicated stuff
        # has to be done to retrieve the new ItemId for the message that gets
        # stored in the Sent Items (or whatever) folder)
#         my $c = 0;
#         my @responses = $self->_list_messages("CreateItem", $create_response);
#         while (my $r = $responses[$c]) {
#            $messages->[$c]->ItemId($responses[$c]->{CreateItemResponseMessage}{Items}{cho_Item}[0]{Message}{ItemId});
#            $c++;
#         }
    }

    if (scalar @to_send) {
        # handle the messages that already exist on the server
        my $send_response = $self->client->SendItems(\@to_send, {
                (exists $opts->{no_saved_copy} && $opts->{no_saved_copy} ? (
                    save_items_to => 'default'
                ) : ()),
            }
        );

        $self->_check_for_errors('SendItem', $send_response);
    }
}

no Moose::Role;
1;
