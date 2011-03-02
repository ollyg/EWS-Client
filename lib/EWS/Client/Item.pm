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

with 'EWS::Client::Role::Serializer';

# this constant is used in the Serializer role to generate FieldURI values for
# attributes where required (initially, just when seriailizing for update, but
# I'm sure there are other places)
use constant FIELDURI_NAMESPACE => 'item';

# this would seem to be a required field, except in the case where we're
# creating new objects, and the server has yet to assign one
#
# This should be treated as an opaque blob.  If required, the individual
# pieces (most notable the ID, beacuse the ChangeKey isn't really useful to
# clients) should be accessed through their 'Id' and 'ChangeKey' aliases
has ItemId => (
    is => 'ro',
    isa => 'HashRef[Str]',
    traits => [qw(Hash Serialized)],
    handles => {
        Id => [ accessor => 'Id' ],
        ChangeKey => [ accessor => 'ChangeKey' ],
    },
    required => 0,
    predicate => 'has_ItemId',
);

has ParentFolderId => (
    is => 'rw',
    isa => 'HashRef[Str]',
    required => 0,
    traits => [qw(Serialized)],
);

has ItemClass => (
    is => 'rw',
    isa => 'Str',
    required => 0,
#    default => 'IPM.Note',
    traits => [qw(Serialized)],
);

has Subject => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    traits => [qw(Serialized)],
);

has Sensitivity => (
    is => 'rw',
    isa => enum([qw/Normal Personal Private Confidential/]),
    required => 0,
    traits => [qw(Serialized)],
);

# XXX override in the Message subclass to make 'rw', so that messages can be
# created from MIME contents
has MimeContent => (
    is => 'ro',
    isa => 'Str',
    traits => [qw(Serialized)],
);

# Not serialized here, pulled into the Body element
has BodyType => (
    is => 'rw',
    isa => 'Str',
    default => 'Text',
);

has Body => (
    is => 'rw',
    isa => 'Str',
    traits => [qw(Serialized)],
    serialization_helper => sub {
        my ($self, $value) = @_;

        return {
            BodyType => $self->BodyType,
            _ => $value,
        };
    },
);

# Attachments

# EWS seems to barf if you pass this in (at least in CreateItem)
has DateTimeReceived => (
    is => 'ro',
    isa => 'DateTime',
#    traits => [qw(Serialized)],
#    serialization_helper => \&format_date,
);

# EWS seems to barf if you pass this in (at least in CreateItem)
has DateTimeSent => (
    is => 'ro',
    isa => 'DateTime',
#    traits => [qw(Serialized)],
#    serialization_helper => \&format_date,
);

# EWS seems to barf if you pass this in (at least in CreateItem)
has DateTimeCreated => (
    is => 'ro',
    isa => 'DateTime',
#    traits => [qw(Serialized)],
#    serialization_helper => \&format_date,
);

# EWS seems to barf if you pass this in (at least in CreateItem)
has Size => (
    is => 'ro',
    isa => 'Int',
#    traits => [qw(Serialized)],
);

has Categories => ( 
    is => 'rw',
    isa => 'ArrayRef[Str]',
    traits => [qw(Serialized)],
    serialization_helper => sub {
        my ($self, $value) = @_;

        return { String => $value };
    },
);

has Importance => (
    is => 'rw',
    isa => enum([qw(Low Normal High)]),
    traits => [qw(Serialized)],
);

has InReplyTo => (
    is => 'rw',
    isa => 'Str',
    traits => [qw(Serialized)],
);

has [qw(IsSubmitted IsDraft IsFromMe IsResend IsUnmodified)] => (
    is => 'rw',
    isa => 'Bool',
    traits => [qw(Serialized)],
);

#has InternetMessageHeaders

#has ResponseObjects

has ReminderDueBy => (
    is => 'rw',
    isa => 'DateTime',
    traits => [qw(Serialized)],
    serialization_helper => \&format_date,
);

has ReminderIsSet => (
    is => 'rw', # XXX ro?
    isa => 'Bool',
    traits => [qw(Serialized)],
);

has ReminderMinutesBeforeStart => (
    is => 'rw', # XXX ro?
    isa => 'Int',
    traits => [qw(Serialized)],
);

# for client use only
has DisplayCc => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
#    traits => [qw(Serialized)],
);

sub has_DisplayCc { return scalar @{(shift)->DisplayCc} }

# for client use only
has DisplayTo => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
#    traits => [qw(Serialized)],
);

sub has_DisplayTo { return scalar @{(shift)->DisplayTo} }

has HasAttachments => (
    is => 'rw', # XXX ro?
    isa => 'Bool',
    traits => [qw(Serialized)],
);

#has ExtendedProperty

has Culture => (
    is => 'rw',
    isa => 'Str',
    traits => [qw(Serialized)],
);

# XXX should add a method that takes the MIME content, parses it, and created 
#  a genuine message object, lazily built, of course

sub has_Body { return length ((shift)->Body) }

# a function used to serialize DateTime objectes in a manner suitable for EWS
sub format_date { 
    my ($self, $value) = @_; 
    return $value->clone->set_time_zone("UTC")->iso8601();
}

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # as a temporary measure, assume that if there's no ItemId stanza in the
    #  data being used to build this object it's a user-created one.  We don't
    #  want to mangle the params for user-created objects.
    return $params unless exists $params->{ItemId};

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
    if (exists $params->{'Body'} and ref $params->{Body} eq 'HASH') {
        $params->{'BodyType'} = $params->{'Body'}->{'BodyType'};
        $params->{'Body'} = $params->{'Body'}->{'_'};
    }
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

