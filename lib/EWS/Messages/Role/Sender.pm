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

sub _create_address_struct {
    my ($self, $addrs) = @_;

    return undef if not defined $addrs;
    $addrs = [ $addrs ] if ref $addrs ne 'ARRAY';

    my $ret = { cho_Mailbox => [ ] };

    foreach my $addr (@$addrs) {
        my $mailbox = { Mailbox => { } };

        if (ref $addr eq 'HASH') {

        $mailbox->{Mailbox} = {
                (exists $addr->{email_address} ? 
                    ( EmailAddress => $addr->{email_address}, ) : ()),
                (exists $addr->{name} ? 
                    ( Name => $addr->{name}, ) : ()),
            };
        } else {
            $mailbox->{Mailbox} = { EmailAddress => $addr };
        }

        push(@{$ret->{cho_Mailbox}}, $mailbox);
    }

    return $ret;
}

# Creates and sends an item.  Cannot send an existing item.
# Options:
#   to, cc, bcc, and reply_to all do the obvious things.  They can be an 
#     individual string containing an email address, a hashref in the
#     following structure 
#        { name => 'display name', email_address => 'address' } 
#     or a list of those elements.  Yes, reply_to can be a list.
#   subject sets the subject of the message
#   body is textual (sorry no formatting available right now) data that makes
#     up the content of the message
#   no_saved_copy => true causes the server to not put a copy of the message
#     in your sent items folder
#   importance, and sensitivity take the same range of values that outlook
#     knows about
#   read_receipt => true causes a read receipt to be requested
#   delivery_receipt => true causes a delivery receipt to be requested
sub send {
    my ($self, $opts) = @_;

    my $to_recipients = $self->_create_address_struct($opts->{to});
    my $cc_recipients = $self->_create_address_struct($opts->{cc});
    my $bcc_recipients = $self->_create_address_struct($opts->{bcc});
    my $reply_to = $self->_create_address_struct($opts->{reply_to});

    my $create_response = $self->client->CreateItem->(
        RequestVersion => {
            Version => $self->client->server_version,
        },

        MessageDisposition => 
            (exists $opts->{no_saved_copy} and $opts->{no_saved_copy} ? 
                "SendOnly" : "SendAndSaveCopy"),
        Items => {
            cho_Item => {
                Message => {
                    ToRecipients => $to_recipients,
                    (defined $cc_recipients ? ( CcRecipients => $cc_recipients, ) : ()),
                    (defined $bcc_recipients ? ( BccRecipients => $bcc_recipients, ) : ()),
                    (defined $reply_to ? ( ReplyTo => $reply_to, ) : ()),
                    (defined $opts->{importance} ? ( Importance => $opts->{importance}, ) : ()),
                    (defined $opts->{sensitivity} ? ( Sensitivity => $opts->{sensitivity}, ) : ()),
                    (defined $opts->{read_receipt} ? ( IsReadReceiptRequested => "true", ) : ()),
                    (defined $opts->{delivery_receipt} ? ( IsDeliveryReceiptRequested => "true", ) : ()),
                    Subject => $opts->{subject},
                    Body => {
                        BodyType => "Text",
                        _ => $opts->{body},
                    },
                }
            }
        }
    );

    $self->_check_for_errors('CreateItem', $create_response);
}

no Moose::Role;
1;
