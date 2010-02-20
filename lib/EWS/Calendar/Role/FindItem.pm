package EWS::Calendar::Role::FindItem;
use Moose::Role;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;

has transporter => (
    is => 'ro',
    isa => 'XML::Compile::Transport::SOAPHTTP',
    lazy_build => 1,
);

sub _build_transporter {
    my $self = shift;
    return XML::Compile::Transport::SOAPHTTP->new( address =>
        sprintf 'https://%s:%s@%s/EWS/Exchange.asmx',
            $self->username, $self->password, $self->server );
}

has http => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_http {
    my $self = shift;
    return $self->transporter->compileClient( action => $self->action );
}

has action => (
    is => 'rw',
    isa => 'Str',
    default => 'http://schemas.microsoft.com/exchange/services/2006/messages/FindItem',
);


has wsdl => (
    is => 'ro',
    isa => 'XML::Compile::WSDL11',
    lazy_build => 1,
);

sub _build_wsdl {
    my $self = shift;

    XML::Compile->addSchemaDirs( $self->schema_path );
    my $wsdl = XML::Compile::WSDL11->new('ews-services.wsdl');
    $wsdl->importDefinitions('ews-types.xsd');
    $wsdl->importDefinitions('ews-messages.xsd');

    return $wsdl;
}

has schema_path => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has FindItem => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_FindItem {
    my $self = shift;
    return $self->wsdl->compileClient(operation => 'FindItem', transport => $self->http);
}

no Moose::Role;
1;

