package EWS::Calendar::Role::Process;
use Moose::Role;

with 'EWS::Calendar::Role::FindItem';
use EWS::Calendar::ResultSet;
use Carp;

sub run {
    my ($self, $query) = @_;

    my $response = scalar $self->FindItem(
        Traversal => 'Shallow',
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
                    /,
                ],
            },
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
            StartDate => $query->start,
            EndDate   => $query->end,
        },
    );

    carp "Fault returned from Exchange Server."
        if $response->{FindItemResult}
                    ->{ResponseMessages}
                    ->{cho_CreateItemResponseMessage}->[0]
                    ->{FindItemResponseMessage}
                    ->{ResponseCode}
                          ne 'NoError';

    return EWS::Calendar::ResultSet->new({
        items => [ map { $_->{CalendarItem} } $response->{FindItemResult}
                                                       ->{ResponseMessages}
                                                       ->{cho_CreateItemResponseMessage}->[0]
                                                       ->{FindItemResponseMessage}
                                                       ->{RootFolder}
                                                       ->{Items}
                                                       ->{cho_Item}->[0] ],
    });
}

no Moose::Role;
1;

