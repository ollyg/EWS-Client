#!/usr/bin/perl

use lib 'lib';
use EWS::Calendar::Read;
use DateTime::Format::ISO8601;

my $cal = EWS::Calendar::Read->new({
    schema_path => 'share',
    username => 'oliver',
    password => $ENV{PASS},
    server => 'nexus.ox.ac.uk',
});

my $set = $cal->retrieve({
    start => DateTime::Format::ISO8601->parse_datetime('2010-02-15T00:00:00Z'),
    end   => DateTime::Format::ISO8601->parse_datetime('2010-02-22T00:00:00Z'),
});

print $set->count ." items\n";

while ($set->has_next) {
    my $item = $set->next;
    print $item->Start->iso8601, "\n";
    print $item->End->iso8601, "\n";
    print $item->Subject, "\n";
    print $item->Body, "\n" if $item->has_Body;
    print $item->Location, "\n" if $item->has_Location;
    print $item->IsRecurring, "\n";
    print $item->Type, "\n";
    print $item->CalendarItemType, "\n";
    print $item->Sensitivity, "\n";
    print join ',', @{$item->DisplayTo}, "\n" if $item->has_DisplayTo;
    print $item->Organizer, "\n";
    print $item->IsCancelled, "\n";
    print $item->AppointmentState, "\n";
    print $item->Status, "\n";
    print $item->LegacyFreeBusyStatus, "\n";
    print $item->IsDraft, "\n";
    print $item->IsAllDayEvent, "\n";
    print "\n";
}

