# log-parser

A streaming web server access log analyzer and query parameter extractor for Common and Combined Log Formats (Nginx/Apache).

## Overview

Designed for high throughput with constant O(1) memory consumption. The parser utilizes pre-compiled regex tokens for zero-copy line evaluation and supports streaming directly from standard input or file descriptors.

## Features

- **Streaming Processing**: Operates line-by-line over filehandles and pipes without loading entire logs into memory.
- **RFC 3986 Decoding**: Automatically extracts and unescapes URI query strings into structured key-value pairs.
- **Multiple Output Formats**: Emits structured CSV, JSON-Lines (NDJSON), or terminal statistical summaries.
- **Traffic Analytics**: Calculates HTTP status code distributions, error ratios (4xx/5xx), bandwidth metrics, and top client/endpoint rankings.

## Requirements

- Perl 5.16+
- Core modules: `Getopt::Long`, `Pod::Usage`, `Test::More`

## Usage

```bash
# Extract specific query parameters to CSV (default)
perl bin/log-parser sample/access.log -f searchbox -p engine -p query -p subengine

# Compute traffic metrics and HTTP status distribution
perl bin/log-parser sample/access.log --stats

# Stream output as JSON-Lines
perl bin/log-parser sample/access.log -f searchbox -o jsonl

# Pipeline processing via STDIN
cat sample/access.log | perl bin/log-parser -f searchbox -o jsonl
```

### CLI Options

| Flag | Argument | Description |
| :--- | :--- | :--- |
| `-f, --filter` | `STRING` | Filter log lines by substring or regex pattern |
| `-p, --param` | `KEY` | Query parameter key to extract (can be specified multiple times) |
| `-o, --format` | `csv|jsonl` | Output serialization format (default: `csv`) |
| `-s, --stats` | None | Aggregate traffic volume, error rates, and top endpoints |
| `-h, --help` | None | Print command-line usage manual |

### Example Output

#### Parameter Extraction (`--format csv`)

```csv
ip,timestamp,status,bytes,request,engine,query,subengine
192.168.1.100,10/Oct/2026:13:55:36 -0700,200,4512,/searchbox?engine=solr&query=amd+epyc&subengine=hardware,solr,amd epyc,hardware
192.168.1.101,10/Oct/2026:13:55:37 -0700,200,2310,/searchbox?engine=google&query=zen5+architecture&subengine=cpu,google,zen5 architecture,cpu
192.168.1.100,10/Oct/2026:13:55:39 -0700,200,3890,/searchbox?engine=bing&query=threadripper+pro&subengine=benchmarks,bing,threadripper pro,benchmarks
```

#### Analytical Summary (`--stats`)

```text
============================================================
                  TRAFFIC & LOG ANALYTICS
============================================================
 Total Requests Processed : 5
 Total Bandwidth          : 0.01 MB
 HTTP Error Rate (4xx/5xx): 40.00%

--- HTTP Status Distribution ---
   Status [200] : 3 requests
   Status [404] : 1 requests
   Status [500] : 1 requests

--- Top 5 Client IPs ---
   192.168.1.100      : 2 hits
   192.168.1.101      : 1 hits
   192.168.1.102      : 1 hits
   192.168.1.103      : 1 hits

--- Top 5 Endpoints ---
   /searchbox               : 3 requests
   /api/v1/metrics          : 1 requests
   /nonexistent-page        : 1 requests
============================================================
```

## Running Tests

Automated unit tests cover log parsing, query unescaping, statistical aggregation, and serialization.

```bash
prove -lv t/
```

```text
t/01_core.t ...... ok
t/02_stats.t ..... ok
t/03_formatter.t . ok
All tests successful.
Result: PASS
```

## Architecture

- `lib/LogParser/Core.pm`: Regular expression engine and RFC 3986 parameter tokenizer.
- `lib/LogParser/Stats.pm`: In-memory accumulator for response codes, bandwidth, and frequency distributions.
- `lib/LogParser/Formatter.pm`: Serializer for RFC 4180 compliant CSV, JSON-Lines, and tabular ASCII reports.
- `bin/log-parser`: CLI entrypoint handling POSIX options and I/O streams.

## License

MIT
