use strict;
use warnings;
use Test::More tests => 5;

use_ok('LogParser::Core');

my $sample = '192.168.1.100 - user [10/Oct/2026:13:55:36 -0700] ' .
             '"GET /searchbox?engine=solr&query=amd+epyc&subengine=hardware HTTP/1.1" ' .
             '200 4512 "https://example.com" "Mozilla/5.0"';

subtest 'Combined log parsing' => sub {
    my $parser = LogParser::Core->new();
    my $res = $parser->parse_line($sample);

    is($res->{ip}, '192.168.1.100', 'IP extracted');
    is($res->{status}, 200, 'Status code parsed as integer');
    is($res->{bytes}, 4512, 'Bytes parsed');
    is($res->{params}{engine}, 'solr', 'Query param matched');
    is($res->{params}{query}, 'amd epyc', 'URL decoding verified');
};

subtest 'Keyword filter' => sub {
    my $parser = LogParser::Core->new(filter => 'searchbox');
    ok($parser->parse_line($sample), 'Matches filter pattern');

    my $parser_mismatch = LogParser::Core->new(filter => 'admin');
    is($parser_mismatch->parse_line($sample), undef, 'Rejects non-matching line');
};

subtest 'Parameter filtering' => sub {
    my $parser = LogParser::Core->new(params => ['engine', 'subengine']);
    my $res = $parser->parse_line($sample);

    is_deeply([sort keys %{$res->{params}}], ['engine', 'subengine'], 'Filtered exact keys');
    is($res->{params}{subengine}, 'hardware', 'Param value matched');
};

subtest 'Invalid line handling' => sub {
    my $parser = LogParser::Core->new();
    is($parser->parse_line('malformed log data'), undef, 'Returns undef on unparseable lines');
};
