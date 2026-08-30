use strict;
use warnings;
use Test::More tests => 3;

use_ok('LogParser::Stats');

my $stats = LogParser::Stats->new();

$stats->record({ ip => '10.0.0.1', request => '/api/v1', status => 200, bytes => 1024 });
$stats->record({ ip => '10.0.0.1', request => '/api/v1', status => 200, bytes => 2048 });
$stats->record({ ip => '10.0.0.2', request => '/api/v2', status => 500, bytes => 512 });

subtest 'Summary aggregation' => sub {
    my $summary = $stats->get_summary();
    is($summary->{total_requests}, 3, 'Request count matched');
    is($summary->{status_codes}{200}, 2, '200 count matched');
    is($summary->{status_codes}{500}, 1, '500 count matched');
    is($summary->{error_rate}, '33.33%', 'Calculated error rate');
};

subtest 'Top rank ordering' => sub {
    my $summary = $stats->get_summary();
    is($summary->{top_ips}[0]{item}, '10.0.0.1', 'Top IP matched');
    is($summary->{top_ips}[0]{count}, 2, 'Frequency matched');
};
