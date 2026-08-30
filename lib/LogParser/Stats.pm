package LogParser::Stats;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    my $self = {
        total_requests => 0,
        total_bytes    => 0,
        status_codes   => {},
        top_ips        => {},
        top_endpoints  => {},
    };
    return bless $self, $class;
}

sub record {
    my ($self, $entry) = @_;
    return unless $entry;

    $self->{total_requests}++;
    $self->{total_bytes} += ($entry->{bytes} || 0);

    my $status = $entry->{status} || 0;
    $self->{status_codes}{$status}++;

    my $ip = $entry->{ip} || 'unknown';
    $self->{top_ips}{$ip}++;

    my $endpoint = ($entry->{request} =~ /^([^?]+)/) ? $1 : ($entry->{request} || '/');
    $self->{top_endpoints}{$endpoint}++;
}

sub get_summary {
    my ($self) = @_;
    
    my $error_count = 0;
    for my $code (keys %{ $self->{status_codes} }) {
        if ($code >= 400) {
            $error_count += $self->{status_codes}{$code};
        }
    }

    my $error_rate = $self->{total_requests} > 0
        ? sprintf("%.2f%%", ($error_count / $self->{total_requests}) * 100)
        : "0.00%";

    return {
        total_requests  => $self->{total_requests},
        total_megabytes => sprintf("%.2f MB", $self->{total_bytes} / (1024 * 1024)),
        error_rate      => $error_rate,
        status_codes    => $self->{status_codes},
        top_ips         => $self->_top_n($self->{top_ips}, 5),
        top_endpoints   => $self->_top_n($self->{top_endpoints}, 5),
    };
}

sub _top_n {
    my ($self, $hashref, $limit) = @_;
    my @sorted = sort { $hashref->{$b} <=> $hashref->{$a} } keys %$hashref;
    my @top;
    for my $i (0 .. ($limit - 1)) {
        last if $i >= @sorted;
        my $k = $sorted[$i];
        push @top, { item => $k, count => $hashref->{$k} };
    }
    return \@top;
}

1;
