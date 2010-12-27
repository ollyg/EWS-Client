package EWS::Client::Role::FindItem;
BEGIN {
  $EWS::Client::Role::FindItem::VERSION = '1.103610';
}
use Moose::Role;

has FindItem => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_FindItem {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'FindItem',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/FindItem' ),
    );
}

no Moose::Role;
1;


__END__
=pod

=head1 NAME

EWS::Client::Role::FindItem

=head1 VERSION

version 1.103610

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

