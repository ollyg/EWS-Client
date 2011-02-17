package EWS::Client::Role::GetItem;
BEGIN {
  $EWS::Client::Role::GetItem::VERSION = '1.103620';
}
use Moose::Role;

has GetItem => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_GetItem {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'GetItem',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/GetItem' ),
    );
}

# takes some options:
# BaseShape is a string which tells EWS what base shape to return
# AdditionalProperties is an arrayref of FieldURIs for fields to return
# Items is an arrayref of ItemIDs to retrieve from the server
sub GetItemsById {
    my ($self, $opts) = @_;

    my %request = (
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
        ItemShape => {
            BaseShape => $opts->{BaseShape} || 'Default',
        },
        ItemIds => {
            cho_ItemId => [
                map {{
                    ItemId => { Id => $_ },
                }} @{$opts->{Items}}
            ],
        },
    );

    if (defined $opts->{AdditionalProperties}) {
        $request{ItemShape}{AdditionalProperties} = {
            cho_Path => [
                map {{
                    FieldURI => {
                        FieldURI => $_, 
                    },  
                }} @{$opts->{AdditionalProperties}},
            ],
        }
    }

#use Data::Dumper;
#print Dumper \%request;

    return scalar $self->GetItem->(%request);
}

no Moose::Role;
1;

