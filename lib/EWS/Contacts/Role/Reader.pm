package EWS::Contacts::Role::Reader;
use Moose::Role;

use EWS::Contacts::ResultSet;
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

sub _list_contactitems {
    my ($self, $kind, $response) = @_;

    return map  { $_->{Contact} }
           grep { defined $_->{'Contact'}->{'DisplayName'} and length $_->{'Contact'}->{'DisplayName'} }
           map  { @{ $_->{Items}->{cho_Item} } }
           map  { exists $_->{RootFolder} ? $_->{RootFolder} : $_ } 
           map  { $_->{"${kind}ResponseMessage"} }
                $self->_list_messages($kind, $response);
}

sub _get_contacts {
    my ($self, @account_id) = @_;

    return scalar $self->client->FindItem->(
        ItemShape => { BaseShape => 'AllProperties' },
        ParentFolderIds => {
            cho_FolderId => [
                { DistinguishedFolderId =>
                    {
                        Id => 'contacts',
                        @account_id, # optional
                    }
                }
            ]
        },
        Traversal => 'Shallow',
    );
}

# find primarysmtp if passed an account id.
# then find contacts in the account.
sub retrieve {
    my ($self, $opts) = @_;

    my $get_response = $self->_get_contacts(
        (exists $opts->{email} ? (Mailbox => { EmailAddress => $opts->{email} }) : ())
    );

    if (exists $get_response->{'ResponseCode'} and defined $get_response->{'ResponseCode'}
        and $get_response->{'ResponseCode'} eq 'ErrorNonPrimarySmtpAddress') {

        $self->retrieve({email => $get_response->{'MessageXml'}->{'Value'}->{'_'}});
    }

    $self->_check_for_errors('FindItem', $get_response);

    return EWS::Contacts::ResultSet->new({
        items => [ $self->_list_contactitems('FindItem', $get_response) ]
    });
}

no Moose::Role;
1;
