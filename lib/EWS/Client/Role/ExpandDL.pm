package EWS::Client::Role::ExpandDL;
use Moose::Role;

has ExpandDL => (
    is         => 'ro',
    isa        => 'CodeRef',
    lazy_build => 1,
);

sub _build_ExpandDL {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'ExpandDL',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/ExpandDL'
        ),
    );
}

no Moose::Role;
1;
