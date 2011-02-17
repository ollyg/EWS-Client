package EWS::Client::Item;
BEGIN {
  $EWS::Client::Item::VERSION = '1.103620';
}
use Moose;

use Moose::Util::TypeConstraints;
use DateTime::Format::ISO8601;
use DateTime;
use HTML::Strip;
use Encode;
use MIME::Base64;

has ItemId => (
    is => 'ro',
    isa => 'HashRef[Str]',
    required => 1,
);

# some aliases for getting individual bits of the ItemId
sub Id { (shift)->ItemId->Id };
sub ChangeKey { (shift)->ItemId->ChangeKey };

has ParentFolderId => (
    is => 'rw',
    isa => 'HashRef[Str]',
    required => 1,
);

has ItemClass => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => 'IPM.Note',
);

has Subject => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has Sensitivity => (
    is => 'rw',
    isa => enum([qw/Normal Personal Private Confidential/]),
    required => 0,
);

# XXX override in the Message subclass to make 'rw', so that messages can be
# created from MIME contents
has MimeContent => (
    is => 'ro',
    isa => 'Str',
);

has Body => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

# Attachments

has DateTimeReceived => (
    is => 'rw',
    isa => 'DateTime',
);

has DateTimeSent => (
    is => 'rw',
    isa => 'DateTime',
);

has DateTimeCreated => (
    is => 'rw',
    isa => 'DateTime',
);

has Size => (
    is => 'rw',
    isa => 'Int',
);

has Categories => ( 
    is => 'rw',
    isa => 'ArrayRef[Str]',
);

has Importance => (
    is => 'rw',
    isa => enum([qw(Low Normal High)]),
);

has InReplyTo => (
    is => 'rw',
    isa => 'Str',
);

has [qw(IsSubmitted IsDraft IsFromMe IsResend IsUnmodified)] => (
    is => 'rw',
    isa => 'Bool',
);

#has InternetMessageHeaders

#has ResponseObjects

has ReminderDueBy => (
    is => 'rw',
    isa => 'DateTime',
);

has ReminderIsSet => (
    is => 'rw', # XXX ro?
    isa => 'Bool',
);

has ReminderMinutesBeforeStart => (
    is => 'rw', # XXX ro?
    isa => 'Int',
);

has DisplayCc => (
    is => 'rw', # XXX ro?
    isa => 'ArrayRef[Str]',
);

sub has_DisplayCc { return scalar @{(shift)->DisplayCc} }

has DisplayTo => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
);

sub has_DisplayTo { return scalar @{(shift)->DisplayTo} }

has HasAttachments => (
    is => 'rw', # XXX ro?
    isa => 'Bool',
);

#has ExtendedProperty

has Culture => (
    is => 'rw',
    isa => 'Str',
);

# XXX should add a method that takes the MIME content, parses it, and created 
#  a genuine message object, lazily built, of course

sub has_Body { return length ((shift)->Body) }

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # could coerce but this is always required, so do it here instead
    my @datetime_fields = qw( 
        DateTimeReceived DateTimeSent DateTimeCreated 
        ReminderDueBy 
    );
    foreach my $field (@datetime_fields) {
        $params->{$field} = DateTime::Format::ISO8601->parse_datetime($params->{$field})
            if exists $params->{$field};
    }

    # fish data out of deep structure
    $params->{'Body'} = $params->{'Body'}->{'_'} if exists $params->{'Body'};
    $params->{'MimeContent'} = decode_base64($params->{'MimeContent'}->{'_'})
        if exists $params->{'MimeContent'};

    # rework semicolon separated lists into array
    $params->{'DisplayTo'} = [ split m/; /, $params->{'DisplayTo'} ]
        if exists $params->{'DisplayTo'};
    $params->{'DisplayCc'} = [ split m/; /, $params->{'DisplayCc'} ]
        if exists $params->{'DisplayCc'};

    # set Perl's encoding flag on all data coming from Exchange
    # also strip HTML tags from incoming data
    my $hs = HTML::Strip->new(emit_spaces => 0);

    foreach my $key (keys %$params) {
        if (ref $params->{$key} eq 'ARRAY') {
            $params->{$key} = [
                map {$hs->parse($_)}
                map {Encode::encode('utf8', $_)}
                    @{ $params->{$key} }
            ];
        }
        elsif (ref $params->{$key}) {
            next;
        }
        else {
            $params->{$key} = Encode::encode('utf8', $params->{$key});
        }
    }

    # the Body is usually a mess if created by Outlook
    if (exists $params->{'Body'}) {
        $params->{'Body'} = $hs->parse($params->{'Body'});
        $params->{'Body'} =~ s/^\s+//;
        $params->{'Body'} =~ s/\s+$//;
        $params->{'Body'} =~ s/\n{3,}/\n\n/g;
        $params->{'Body'} =~ s/ {2,}/ /g;
    }

    return $params;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

