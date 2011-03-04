package EWS::Client::Role::SendItem;
BEGIN {
  $EWS::Client::Role::SendItem::VERSION = '1.103620';
}
use Moose::Role;

has SendItem => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_SendItem {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'SendItem',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/SendItem' ),
    );
}

sub SendItems {
    my ($self, $items, $opts) = @_;

    $items = [ $items ] unless ref $items eq 'ARRAY';
    return undef unless scalar @$items;

    my $save = exists $opts->{save_items_to} && $opts->{save_items_to} ? 
        "true" : "false";

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

        SaveItemToFolder => $save,
        ($save eq "true" && $opts->{save_items_to} ne "default" ? (
            SavedItemFolderId => $opts->{save_items_to}
        ) : ()),

        # XXX need to provide a facility to specify a target folder

        ItemIds => { },
    };

    # plug in the serialized representations of the items to be created
    $request->{ItemIds}{cho_ItemId} = [ map { $_->serialize(['ItemId'], {as_fields => 1}) } @$items ];

    return scalar $self->SendItem->($request);
}

no Moose::Role;
1;

