package EWS::Client::Role::SOAP;
BEGIN {
  $EWS::Client::Role::SOAP::VERSION = '1.103610';
}
use Moose::Role;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use File::ShareDir ();

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
    lazy_build => 1,
);

sub _build_schema_path {
    my $self = shift;
    return File::ShareDir::dist_dir('EWS-Client');
}

no Moose::Role;
1;


__END__
=pod

=head1 NAME

EWS::Client::Role::SOAP

=head1 VERSION

version 1.103610

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

