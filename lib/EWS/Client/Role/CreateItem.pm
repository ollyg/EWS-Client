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

no Moose::Role;
1;

