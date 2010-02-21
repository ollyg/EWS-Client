package EWS::Calendar::Read;
use Moose;

with 'EWS::Calendar::Role::RunFindItemQuery';
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

sub retrieve {
    my $self = shift;
    my $query = EWS::Calendar::Query->new(@_);
    return $self->run($query);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 NAME

EWS::Calendar::Read - Read Calendar Entries from Microsoft Exchange Server

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
 
 my $entries = $cal->retrieve({
     start => DateTime::Format::ISO8601->parse_datetime('2010-02-15T00:00:00Z'),
     end   => DateTime::Format::ISO8601->parse_datetime('2010-02-22T00:00:00Z'),
 });
 
 print "I retrieved ". $entries->count ." items\n";
 
 while ($entries->has_next) {
     print $entries->next->Subject, "\n";
 }

=head1 DESCRIPTION

This module will connect to a Microsoft Exchange server and retrieve the
calendar entries within a given time window. The results are available in an
iterator and convenience methods exist to access the properties of each entry.

=head1 METHODS

=head2 CONSTRUCTOR

=head2 EWS::Calendar::Read->new( \%arguments )

Instantiates a new calendar reader. Note that the action of performing a query
for a set of results is separated from this step, so you can perform multiple
queries using this same object. Pass the following arguments in a hash ref:

=over 4

=item C<schema_path> => String (required)

A folder on your file system which contains the WSDL and two further Schema
files which describe the Exchange 2007 Web Services SOAP API.

=item C<username> => String (required)

The account username under which the module will connect to Exchange. This
value will be URI encoded by the module.

=item C<password> => String (required)

The password of the account under which the module will connect to Exchange.
This value will be URI encoded by the module.

=item C<server> => Fully Qualified Domain Name (required)

The host name of the Exchange server to which the module should connect.

=back

=head2 QUERY AND RESULT SET

=head2 $cal->retrieve( \%arguments )

Query the Exchange server and retrieve calendar entries between the given
timestamps. Pass the following arguments in a hash ref:

=over 4

=item C<start> => DateTime object (required)

Entries with an end date on or after this timestamp will be included in the
returned results.

=item C<end> => DateTime object (required)

Entries with a start date before this timestamp will be included in the
results.

=back

The returned object contains the collection of calendar entries which matched
the start and end criteria, and is of type C<EWS::Calendar::ResultSet>. It's
an iterator, so you can walk through the list of entries (see the synposis,
above). For example:

 my $entries = $cal->retrieve({start => '', end => ''});

=head2 $entries->next

Provides the next item in the collection of calendar entries, or C<undef> if
there are no more items to return. Usually used in a loop along with
C<has_next> like so:

 while ($entries->has_next) {
     print $entries->next->Subject, "\n";
 }

=head2 $entries->peek

Returns the next item without moving the state of the iterator forward. It
returns C<undef> if it is at the end of the collection and there are no more
items to return.

=head2 $entries->has_next

Returns a true value if there is another entry in the collection after the
current item, otherwise returns a false value.

=head2 $entries->reset

Resets the iterator's cursor, so you can walk through the entries again from
the start.

=head2 $entries->count

Returns the number of entries returned by the C<retrieve> server query.

=head2 $entries->items

Returns an array ref containing all the entries returned by the C<retrieve>
server query. They are each objects of type C<EWS::Calendar::Item>.

=head2 ITEM PROPERTIES

These descriptions are taken from Microsoft's on-line documentation.

=head2 $item->Start

A L<DateTime> object representing the starting date and time for a calendar
item.

=head2 $item->End

A L<DateTime> object representing the ending date and time for a calendar
item.

=head2 $item->Subject

Represents the subject of a calendar item.

=head2 $item->Location (optional)

Friendly name for where a calendar item pertains to (e.g., a physical address
or "My Office").

=head2 $item->has_Location

Will return true if the event item had a Location property set, meaning there
is a defined value in C<< $item->Location >>, otherwise returns false.

=head2 $item->Type

The type of calendar item indicating its relationship to a recurrence, if any.
This will be a string value of one of the following, only:

=over 4

=item * Single

=item * Occurrence

=item * Exception

=back

=head2 $item->CalendarItemType

This is an alias (the native name, in fact) for the C<< $item->Type >>
property.

=head2 $item->Sensitivity

Indicates the sensitivity of the item, which can be used to filter information
your user sees. Will be a string and one of the following four values, only:

=over 4

=item * Normal

=item * Personal

=item * Private

=item * Confidential

=back

=head2 $item->DisplayTo (optional)

When a client creates a calendar entry, there can be other people invited to
the event (usually via the To: box in Outlook, or similar). This property
contains an array ref of the display names ("Firstname Lastname") or the
parties invited to the event.

=head2 $item->has_DisplayTo

Will return true if there are entries in the C<< $item->DisplayTo >> property,
in other words there were invitees on this event, otherwise returns false.
Actually returns the number of entries in that list, which may be useful.

=head2 $item->Organizer

The display name (probably "Firstname Lastname") of the party responsible for
creating the entry.

=head2 $item->IsCancelled

True if the calendar item has been cancelled, otherwise false.

=head2 $item->AppointmentState

Contains a bitmask of flags on the entry, but you probably want to use
C<IsCancelled> instead.

=head2 $item->Status

Free/busy status for a calendar item, which can actually be one of the
following four string values:

=over 4

=item * Free

=item * Tentative

=item * Busy

=item * OOF (means Out Of Office)

=item * NoData (means something went wrong)

=back

=head2 $item->LegacyFreeBusyStatus

This is an alias (the native name, in fact) for the C<< $item->Status >>
property.

=head2 $item->IsDraft

Indicates whether an item has not yet been sent.

=head2 $item->IsAllDayEvent

True if a calendar item is to be interpreted as lasting all day, otherwise
false.

=head1 TODO

This module family could be expanded into something more generic and
scaleable. For example:

 my $ews = EWS::Server->new(\%args);
 
 my $cal = $ews->calendar;
 $cal->retrieve({start => , end => });
 $cal->update(\%args);
 $cal->delete(\%args);
 
 my $contacts = $ews->contacts({for => 'another.user@ews.example.com'});
 $contacts->retrieve;

...and so on. I already have the contacts code so will probably implement the
above in due course, if the tuits appear.

I might also look at moving away from L<XML::Compile>, which is truely the
most awesome of modules, but overkill for ths very small set of static calls.

There is currently no handling of time zone information whatsoever. I'm
waiting for my timezone to shift to UTC+1 in March before working on this, as
I don't really want to read the Exchange API docs. Patches are welcome if you
want to help out.

=head1 REQUIREMENTS

=over 4

=item * L<XML::Compile::SOAP>

=item * L<Moose>

=item * L<DateTime>

=back

=head1 SEE ALSO

=over 4

=item * L<http://msdn.microsoft.com/en-us/library/aa580675.aspx>

=back

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) Oliver Gorwits 2010.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
