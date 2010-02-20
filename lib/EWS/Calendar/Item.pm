package EWS::Calendar::Item;
use Moose;

# guaranteed data
has $_ => (
    is => 'ro',
    isa => 'Str',
    required => 1,
) for qw/
    Start
    End
    Subject
    CalendarItemType
    Sensitivity
    DisplayTo
    AppointmentState
    LegacyFreeBusyStatus
    IsDraft
/;

# optional data
has $_ => (
    is => 'ro',
    isa => 'Str',
    predicate => "has_$_",
) for qw/
    Location
    IsAllDayEvent
/;

__PACKAGE__->meta->make_immutable;
no Moose;
1;
