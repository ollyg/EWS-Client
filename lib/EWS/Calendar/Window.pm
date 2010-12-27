package EWS::Calendar::Window;
BEGIN {
  $EWS::Calendar::Window::VERSION = '1.103610';
}
use Moose;

use DateTime;

has start => (
    is => 'ro',
    isa => 'DateTime',
    required => 1,
);

has end => (
    is => 'ro',
    isa => 'DateTime',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;


__END__
=pod

=head1 NAME

EWS::Calendar::Window

=head1 VERSION

version 1.103610

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

