package EWS::Client::Role::CreateItem;
BEGIN {
  $EWS::Client::Role::CreateItem::VERSION = '1.103620';
}
use Moose::Role;

has CreateItem => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_CreateItem {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'CreateItem',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/CreateItem' ),
    );
}

sub CreateItems {
    my ($self, $items, $opts) = @_;

    $items = [ $items ] unless ref $items eq 'ARRAY';

    my $request = {
        (exists $opts->{impersonate} ? (
            Impersonation => {
                ConnectingSID => {
                    PrimarySmtpAddress => $opts->{impersonate},
                }
            },
        ) : ()),
        
        RequestVersion => {
            Version => $self->server_version,
        },

        MessageDisposition => $opts->{action} || "SaveOnly",
        SendMeetingInvitations => $opts->{meeting_invites} || "SendToNone",

        # XXX need to provide a facility to specify a target folder

        Items => { },
    };

    # plug in the serialized representations of the items to be created
    $request->{Items}{cho_Item} = [ map { $_->serialize() } @$items ];

    return scalar $self->CreateItem->($request);
}

no Moose::Role;
1;

