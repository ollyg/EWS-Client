package EWS::Calendar::Role::Reader;
BEGIN {
  $EWS::Calendar::Role::Reader::VERSION = '1.103610';
}
use Moose::Role;

with 'EWS::Calendar::Role::RetrieveWithinWindow';
use EWS::Calendar::Window;

sub retrieve {
    my $self = shift;
    my $window = EWS::Calendar::Window->new(@_);
    return $self->retrieve_within_window($window);
}

no Moose::Role;
1;

__END__
=pod

=head1 NAME

EWS::Calendar::Role::Reader

=head1 VERSION

version 1.103610

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

