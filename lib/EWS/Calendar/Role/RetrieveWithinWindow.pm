package EWS::Calendar::Role::RetrieveWithinWindow;
BEGIN {
  $EWS::Calendar::Role::RetrieveWithinWindow::VERSION = '1.103610';
}
use Moose::Role;

use EWS::Calendar::ResultSet;
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

sub _list_calendaritems {
    my ($self, $kind, $response) = @_;

    return map { $_->{CalendarItem} }
           map { @{ $_->{Items}->{cho_Item} || [] } }
           map { exists $_->{RootFolder} ? $_->{RootFolder} : $_ } 
           map { $_->{"${kind}ResponseMessage"} }
               $self->_list_messages($kind, $response);
}

# Find list of items within the view, then Get details for each one
# (item:Body is only available this way, it's not returned by FindItem)
sub retrieve_within_window {
    my ($self, $query) = @_;

    my $find_response = scalar $self->client->FindItem->(
        Traversal => 'Shallow',
        ItemShape => {
            BaseShape => 'IdOnly',
        },
        ParentFolderIds => {
            cho_FolderId => [
                {
                    DistinguishedFolderId => {
                        Id => "calendar",
                    },
                },
            ],
        },
        CalendarView => {
            StartDate => $query->start->iso8601,
            EndDate   => $query->end->iso8601,
        },
    );

    $self->_check_for_errors('FindItem', $find_response);

    my @ids = map { $_->{ItemId}->{Id} }
                  $self->_list_calendaritems('FindItem', $find_response);

    return return EWS::Calendar::ResultSet->new({items => []})
        if scalar @ids == 0;

    my $get_response = scalar $self->client->GetItem->(
        ItemShape => {
            BaseShape => 'IdOnly',
            AdditionalProperties => {
                cho_Path => [
                    map {{
                        FieldURI => {
                            FieldURI => $_, 
                        },  
                    }} qw/ 
                        calendar:Start
                        calendar:End
                        item:Subject
                        calendar:Location
                        calendar:CalendarItemType
                        calendar:Organizer
                        item:Sensitivity
                        item:DisplayTo
                        calendar:AppointmentState
                        calendar:IsAllDayEvent
                        calendar:LegacyFreeBusyStatus
                        item:IsDraft
                        item:Body
                    /,
                ],
            },
        },
        ItemIds => {
            cho_ItemId => [
                map {{
                    ItemId => { Id => $_ },
                }} @ids
            ],
        },
    );

    $self->_check_for_errors('GetItem', $get_response);

    return EWS::Calendar::ResultSet->new({
        items => [ $self->_list_calendaritems('GetItem', $get_response) ]
    });
}

no Moose::Role;
1;


__END__
=pod

=head1 NAME

EWS::Calendar::Role::RetrieveWithinWindow

=head1 VERSION

version 1.103610

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

