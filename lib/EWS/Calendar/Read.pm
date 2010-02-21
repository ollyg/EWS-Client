package EWS::Calendar::Read;
use Moose;

with 'EWS::Calendar::Role::Process';
use EWS::Calendar::Query;

our $VERSION = '0.01';
$VERSION = eval $VERSION; # numify for warning-free dev releases

has username => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has password => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has server => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub view {
    my $self = shift;
    my $query = EWS::Calendar::Query->new(@_);
    return $self->run($query);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 NAME

EWS::Calendar::Read - Calendar Events from Microsoft Exchange Server 2007

=head1 VERSION

This document refers to version 0.01 of EWS::Calendar::Read

=head1 SYNOPSIS

 use EWS::Calendar::Read;
 use DateTime::Format::ISO8601;
 
 my $cal = EWS::Calendar::Read->new({
     schema_path => '/path/to/local/ews/schema',
     username    => 'oliver',
     password    => 's3krit',
     server      => 'exchangeserver.example.com',
 });
 
 my $entries = $cal->view({
     start => DateTime::Format::ISO8601->parse_datetime('2010-02-15T00:00:00Z'),
     end   => DateTime::Format::ISO8601->parse_datetime('2010-02-22T00:00:00Z'),
 });
 
 print "I retrieved ". $entries->count ." items\n";
 
 my $iter = $entries->iter;
 while ($iter->has_next) {
     print $iter->next->Subject, "\n";
 }

=head1 DESCRIPTION

=head1 CONFIGURATION

=head1 METHODS

=head2 Constructor

=head2 Query and Result Set

=head2 Item Attributes


=head1 REQUIREMENTS

=over 4

=item * L<XML::Compile::SOAP>

=item * L<Moose>

=item * L<DateTime>

=back

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) Oliver Gorwits 2010.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
