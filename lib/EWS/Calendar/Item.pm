package EWS::Calendar::Item;
use Moose;

use Moose::Util::TypeConstraints;
use DateTime::Format::ISO8601;
use DateTime;

has Start => (
    is => 'ro',
    isa => 'DateTime',
    required => 1,
);

has End => (
    is => 'ro',
    isa => 'DateTime',
    required => 1,
);

has Subject => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has Location => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => '',
);

has CalendarItemType => (
    is => 'ro',
    isa => enum([qw/Single Occurrence Eception/]),
    required => 1,
);

sub Type { (shift)->CalendarItemType }

has Sensitivity => (
    is => 'ro',
    isa => enum([qw/Normal Personal Private Confidential/]),
    required => 1,
);

has DisplayTo => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
);

has Organizer => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has IsCancelled => (
    is => 'ro',
    isa => 'Int', # bool
    required => 1,
);

has AppointmentState => (
    is => 'ro',
    isa => 'Int', # bool
    required => 1,
);

has LegacyFreeBusyStatus => (
    is => 'ro',
    isa => enum([qw/Free Tentative Busy OOF NoData/]),
    required => 1,
);

sub Status  { (shift)->LegacyFreeBusyStatus }

has IsDraft => (
    is => 'ro',
    isa => 'Int', # bool
    required => 1,
);

has IsAllDayEvent => (
    is => 'ro',
    isa => 'Int', # bool
    required => 0,
    default => 0,
);

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    $params->{'Start'} = DateTime::Format::ISO8601->parse_datetime($params->{'Start'});
    $params->{'End'}   = DateTime::Format::ISO8601->parse_datetime($params->{'End'});
    $params->{'Organizer'}   = $params->{'Organizer'}->{'Mailbox'}->{'Name'};
    $params->{'IsCancelled'} = ($params->{'AppointmentState'} & 0x0004);
    $params->{'DisplayTo'}   = [ grep {$_ ne $params->{'Organizer'}}
                                      split m/; /, $params->{'DisplayTo'} ];
    return $params;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
