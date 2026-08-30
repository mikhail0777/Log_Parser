package LogParser::Core;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '1.0.0';

# Standard Nginx/Apache Combined Log Format (CLF)
my $LOG_REGEX = qr{
    ^
    (?P<ip>\S+)\s+
    (?P<ident>\S+)\s+
    (?P<authuser>\S+)\s+
    \[(?P<timestamp>[^\]]+)\]\s+
    "(?P<method>[A-Z]+)\s+
     (?P<request>[^\s"]+)\s*
     (?P<protocol>[^"]*)"\s+
    (?P<status>\d{3})\s+
    (?P<bytes>\S+)
    (?:
        \s+"(?P<referer>[^"]*)"\s+
        "(?P<user_agent>[^"]*)"
    )?
    $
}x;

sub new {
    my ($class, %args) = @_;
    my $self = {
        filter_pattern => defined $args{filter} ? qr/$args{filter}/i : undef,
        target_params  => $args{params} || [],
    };
    return bless $self, $class;
}

sub parse_line {
    my ($self, $line) = @_;
    return undef unless defined $line;

    if (defined $self->{filter_pattern}) {
        return undef unless $line =~ $self->{filter_pattern};
    }

    if ($line =~ $LOG_REGEX) {
        my %entry = (
            ip         => $+{ip},
            authuser   => $+{authuser},
            timestamp  => $+{timestamp},
            method     => $+{method},
            request    => $+{request},
            protocol   => $+{protocol} || '',
            status     => int($+{status}),
            bytes      => ($+{bytes} eq '-' ? 0 : int($+{bytes})),
            referer    => $+{referer} || '',
            user_agent => $+{user_agent} || '',
        );

        $entry{params} = $self->_extract_query_params($entry{request});
        return \%entry;
    }

    return undef;
}

sub _extract_query_params {
    my ($self, $uri) = @_;
    my %params;

    if ($uri =~ /\?(.+)$/) {
        my $query_string = $1;
        for my $pair (split /&/, $query_string) {
            my ($key, $val) = split /=/, $pair, 2;
            next unless defined $key;
            $val = '' unless defined $val;
            
            # RFC 3986 decode
            $key =~ tr/+/ /;
            $key =~ s/%([a-fA-F0-9]{2})/chr(hex($1))/eg;
            $val =~ tr/+/ /;
            $val =~ s/%([a-fA-F0-9]{2})/chr(hex($1))/eg;

            $params{$key} = $val;
        }
    }

    if (@{ $self->{target_params} }) {
        my %filtered;
        for my $p (@{ $self->{target_params} }) {
            $filtered{$p} = $params{$p} // '';
        }
        return \%filtered;
    }

    return \%params;
}

1;
