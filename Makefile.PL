use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'LogParser::Enterprise',
    VERSION_FROM => 'lib/LogParser/Core.pm',
    ABSTRACT     => 'High-throughput Apache/Nginx access log parser and metrics aggregator',
    EXE_FILES    => ['bin/log-parser'],
    PREREQ_PM    => {
        'Test::More'   => 0,
        'Getopt::Long' => 0,
        'Pod::Usage'   => 0,
        'Carp'         => 0,
    },
    test => { TESTS => 't/*.t' },
);
