package LogParser::Formatter;

use strict;
use warnings;

sub format_csv_header {
    my ($class, @param_keys) = @_;
    return join(',', 'ip', 'timestamp', 'status', 'bytes', 'request', @param_keys) . "\n";
}

sub format_csv_row {
    my ($class, $entry, @param_keys) = @_;
    my @row = (
        _escape_csv($entry->{ip}),
        _escape_csv($entry->{timestamp}),
        $entry->{status},
        $entry->{bytes},
        _escape_csv($entry->{request}),
    );
    for my $k (@param_keys) {
        push @row, _escape_csv($entry->{params}{$k} // '');
    }
    return join(',', @row) . "\n";
}

sub format_json_line {
    my ($class, $entry) = @_;
    my @pairs;
    for my $k (qw(ip timestamp method request status bytes referer user_agent)) {
        my $v = $entry->{$k} // '';
        push @pairs, sprintf('"%s":%s', $k, ($k =~ /^(status|bytes)$/ ? int($v) : _escape_json($v)));
    }
    
    my @param_pairs;
    for my $pk (sort keys %{ $entry->{params} || {} }) {
        push @param_pairs, sprintf('"%s":%s', $pk, _escape_json($entry->{params}{$pk}));
    }
    push @pairs, sprintf('"params":{%s}', join(',', @param_pairs));

    return "{" . join(',', @pairs) . "}\n";
}

sub format_terminal_summary {
    my ($class, $summary) = @_;
    my $out = "\n" . ("=" x 60) . "\n";
    $out .= "                  TRAFFIC & LOG ANALYTICS\n";
    $out .= ("=" x 60) . "\n";
    $out .= sprintf(" Total Requests Processed : %d\n", $summary->{total_requests});
    $out .= sprintf(" Total Bandwidth          : %s\n", $summary->{total_megabytes});
    $out .= sprintf(" HTTP Error Rate (4xx/5xx): %s\n", $summary->{error_rate});
    
    $out .= "\n--- HTTP Status Distribution ---\n";
    for my $code (sort keys %{ $summary->{status_codes} }) {
        $out .= sprintf("   Status [%d] : %d requests\n", $code, $summary->{status_codes}{$code});
    }

    $out .= "\n--- Top 5 Client IPs ---\n";
    for my $item (@{ $summary->{top_ips} }) {
        $out .= sprintf("   %-18s : %d hits\n", $item->{item}, $item->{count});
    }

    $out .= "\n--- Top 5 Endpoints ---\n";
    for my $item (@{ $summary->{top_endpoints} }) {
        $out .= sprintf("   %-24s : %d requests\n", $item->{item}, $item->{count});
    }
    $out .= ("=" x 60) . "\n";
    return $out;
}

sub _escape_csv {
    my ($val) = @_;
    $val = '' unless defined $val;
    if ($val =~ /[,"]/ || $val =~ /\n/) {
        $val =~ s/"/""/g;
        return qq{"$val"};
    }
    return $val;
}

sub _escape_json {
    my ($val) = @_;
    $val = '' unless defined $val;
    $val =~ s/\\/\\\\/g;
    $val =~ s/"/\\"/g;
    $val =~ s/\n/\\n/g;
    $val =~ s/\r/\\r/g;
    $val =~ s/\t/\\t/g;
    return qq{"$val"};
}

1;
