#!/usr/bin/perl

use lib 'lib';
use EWS::Calendar::Read;

my $cal = EWS::Calendar::Read->new({
    schema_path => 'share',
    username => 'oliver',
    password => $ENV{PASS},
    server => 'nexus.ox.ac.uk',
});

my $set = $cal->view({
    start => '2010-02-15T00:00:00Z',
    end   => '2010-02-22T00:00:00Z',
});

print $set->count ." items\n";

my $iter = $set->iter;
while ($iter->has_next) {
    print $iter->next->Subject, "\n";
}

