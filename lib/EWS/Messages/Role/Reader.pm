package EWS::Messages::Role::Reader;
BEGIN {
  $EWS::Messages::Role::Reader::VERSION = '1.103620';
}
use Moose::Role;

use EWS::Messages::ResultSet;
use Carp;

sub _list_messages {
    my ($self, $kind, $response) = @_;
    return @{ $response->{"${kind}Result"}
                       ->{ResponseMessages}
                       ->{"cho_CreateItemResponseMessage"} };
}

sub _check_for_errors {
    my ($self, $kind, $response) = @_;

    foreach my $msg ( $self->_list_messages($kind, $response) ) {
        my $code = $msg->{"${kind}ResponseMessage"}->{ResponseCode} || '';
        croak "Fault returned from Exchange Server: $code\n"
            if $code ne 'NoError';
    }
}

sub _list_message_items {
    my ($self, $kind, $response) = @_;

    # XXX Note the || sequence in the first map command, it's there because
    #  various non-Message items can be returned because they can live in
    #  a folder where you'd expect messages
    return map { $_->{Message} || $_->{MeetingRequest} || $_->{MeetingCancellation} || $_->{MeetingResponse} }
           map { @{ $_->{Items}->{cho_Item} || [] } }
           map { exists $_->{RootFolder} ? $_->{RootFolder} : $_ } 
           map { $_->{"${kind}ResponseMessage"} }
               $self->_list_messages($kind, $response);
}

# This is a development artifact.  It's a POC function that retrieves mail
#  from the inbox.  It requires a date&time string in the proper format
#  ("2011-02-16T08:00:00Z") to be passed as "Since".  That's used as a 
#  restriction to avoid pulling all mail.
sub retrieve_inbox {
    my ($self, $opts) = @_;

    my $find_response = scalar $self->client->FindItems_Simple({
        BaseShape => 'IdOnly',
        InFolders => ['inbox'],
        Restriction => {
            IsGreaterThan => {
                FieldURI => { FieldURI => "item:DateTimeReceived" },
                FieldURIOrConstant => {
                    Constant => { Value => $opts->{Since} },
                },
            },
        },
    });

    $self->_check_for_errors('FindItem', $find_response);

    my @ids = map { $_->{ItemId}->{Id} }
                  $self->_list_message_items('FindItem', $find_response);

    return return EWS::Messages::ResultSet->new({items => []})
        if scalar @ids == 0;

    my $get_response = $self->client->GetItemsById({
        BaseShape => 'IdOnly',
        AdditionalProperties => [qw(
            item:ItemId
            item:ParentFolderId
            item:Subject
            item:Body
            item:DateTimeReceived
            message:From
            message:Sender
            message:InternetMessageId)],
        Items => \@ids,
    });

    $self->_check_for_errors('GetItem', $get_response);

    return EWS::Messages::ResultSet->new({
        items => [ $self->_list_message_items('GetItem', $get_response) ]
    });
}

no Moose::Role;
1;

