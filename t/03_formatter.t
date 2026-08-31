use strict;
use warnings;
use Test::More tests => 3;

use_ok('LogParser::Formatter');

my $entry = {
    ip        => '127.0.0.1',
    timestamp => '10/Oct/2026:12:00:00 -0400',
    method    => 'GET',
    request   => '/test,path',
    status    => 200,
    bytes     => 1024,
    params    => { query => 'amd epyc, zen 5' },
};

subtest 'CSV formatting' => sub {
    my $csv = LogParser::Formatter->format_csv_row($entry, 'query');
    like($csv, qr/"\/test,path"/, 'Escaped URI comma');
    like($csv, qr/"amd epyc, zen 5"/, 'Escaped param comma');
};

subtest 'JSON Lines output' => sub {
    my $json = LogParser::Formatter->format_json_line($entry);
    like($json, qr/"ip":"127\.0\.0\.1"/, 'IP serialized');
    like($json, qr/"status":200/, 'Integer status serialized without quotes');
    like($json, qr/"query":"amd epyc, zen 5"/, 'Nested param serialized');
};
