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
    print $set->next->Subject, "\n";
}

