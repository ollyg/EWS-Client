package EWS::Contacts::Role::Reader;
use Moose::Role;

use EWS::Contacts::EntryResultSet;
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

    return map { $_->{Contact} }
           map { @{ $_->{Items}->{cho_Item} } }
           map { exists $_->{RootFolder} ? $_->{RootFolder} : $_ } 
           map { $_->{"${kind}ResponseMessage"} }
               $self->_list_messages($kind, $response);
}

# find primarysmtp if passed an account id.
# then find contacts in the account.
sub retrieve {
    my ($self, $opts) = @_;
    my @account_id = ();

    if (defined $opts->{email}) {
        # the email passed might not be the primarysmtp, and we need that to
        # refer to the account. Exchange will return the primarysmtp in an error.

        my $primarysmtp_response = scalar $self->client->FindItem->(
            ItemShape => { BaseShape => 'AllProperties' },
            ParentFolderIds => {
                    cho_FolderId => [
                        { DistinguishedFolderId =>
                            {   
                                Id => 'contacts',
                                Mailbox => { EmailAddress => $opts->{email} }
                            }   
                        }   
                    ]   
                },  
            Traversal => 'Shallow',
        );

        my $msg = [$self->_list_messages('FindItem', $primarysmtp_response)]->[0];
        my $primarysmtp = $opts->{email}; # last resort

        if (defined $msg->{'ResponseCode'}) {
            if ($msg->{'ResponseCode'} eq 'ErrorNonPrimarySmtpAddress') { # good
                $primarysmtp = $msg->{'MessageXml'}->{'Value'}->{'_'};
            }
            elsif ($msg->{'ResponseCode'} eq 'NoError') { # strange, but good
                $primarysmtp = $opts->{email};
            }
            else { # error?!
                $self->_check_for_errors('FindItem', $primarysmtp_response);
            }
        }

        @account_id = (Mailbox => { EmailAddress => $primarysmtp });
    }

    my $get_response = scalar $self->client->FindItem->(
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

    $self->_check_for_errors('FindItem', $get_response);

    return EWS::Contacts::EntryResultSet->new({
        items => [ $self->_list_contactitems('FindItem', $get_response) ]
    });
}

no Moose::Role;
1;

