#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use FindBin '$Bin';
use Getopt::Long;
use JSON::PP ();
use JSON::XS ();
use Cpanel::JSON::XS ();
use Mojolicious ();
use Mojo::JSON ();
use JSON::Tiny ();
use YAML ();
use YAML::Syck ();
    $YAML::Syck::ImplicitTyping = 1;
use YAML::XS ();
use YAML::PP ();
use Text::Table;
use Devel::Peek ();
use HTML::Template::Compiled;

GetOptions(
    "format=s" => \my $format,
);

$format ||= 'text';

my @data;

my @codes = (
    q{$x = 10},
    <<'EOM',
$x = 11;
$x .= "";
$x
EOM
    <<'EOM',
$x = 12;
$x .= "x";
$x += 0;
$x
EOM
    <<'EOM',
$x = 13;
$y = $x . "string";
$x
EOM
    <<'EOM',
$x = 14;
$x .= "";
$x += 0;
$x
EOM
    <<'EOM',
$x = 15;
$x .= "";
$y = $x + 1;
$x
EOM
    q{$x = "16"},
    <<'EOM',
$x = "17";
$x += 0;
$x
EOM
    <<'EOM',
$x = "18";
$y = $x + 0;
$x
EOM
    <<'EOM',
$x = 19;
$x .= "x";
$y = $x + 0;
$x
EOM
    q{$x = 2e1},
    <<'EOM',
$x = "021";
$y = $x + 0;
$x
EOM
    <<'EOM',
$x = 22.1;
$x
EOM
    <<'EOM',
$x = 23.1;
$y = $x . '';
$x
EOM
    <<'EOM',
$x = 24.1;
$x .= '';
$x
EOM
    <<'EOM',
$x = "25.0";
$y = $x + 0;
$x
EOM
    q{$x = 0 + "inf"},
    q{$x = 0 - "inf"},
    q{$x = 0 + "nan"},
    <<'EOM',
$x = "0 but true";
$y = 1 + $x;
$x
EOM
);

for my $code (@codes) {
    push @data, eval 'no warnings; my ($x, $y);' . $code;
}


my @json = qw/ JSON::PP JSON::XS Cpanel::JSON::XS JSON::Tiny Mojo::JSON /;
my @yaml = qw/ YAML YAML::XS YAML::Syck YAML::PP /;

my @headers;
my @versions;
my @rows;
if ($format eq 'html') {
    @headers = ('', '', qw/ INT FLOAT STRING /, @json, @yaml);
    @versions = ('','','','','');
}
else {
    @headers = ('', '', qw/ INT FLOAT STRING /, @json, @yaml);
    @versions = ('','','','','');
}
my $i = 0;
for my $fw (@json, @yaml) {
    my $version = $fw eq 'Mojo::JSON' ? Mojolicious->VERSION: $fw->VERSION;
    push @versions, $version;
}
if ($format eq 'html') {
    push @rows, [map {
        +{ type => (length $? ? 'version' : ''), value => $_ }
    } @versions];
}
else {
    push @rows, \@versions;
}


for my $i (0 .. $#data) {
    my $item = $data[ $i ];
    my $code = $codes[ $i ] // '-';
#    Devel::Peek::Dump $item;
    my $flags = B::svref_2object(\$item)->FLAGS;
    my $intflag = $flags & B::SVp_IOK ? 'x' : '';
    my $floatflag = $flags & B::SVp_NOK ? 'x' : '';
    my $stringflag = $flags & B::SVp_POK ? 'x' : '';

    my @row;
    $i++;
    if ($format eq 'html') {
        push @row, { type => 'index', value => $i };
        push @row, { type => 'code', value => $code };
        push @row, { type => "flag$intflag", value => $intflag };
        push @row, { type => "flag$floatflag", value => $floatflag };
        push @row, { type => "flag$stringflag", value => $stringflag };
    }
    else {
        push @row, $i;
        push @row, $code;
        push @row, $intflag, $floatflag, $stringflag;
    }
    for my $fw (@json) {
        my $can = $fw->can("encode_json");
        my $json = $can->([$item]);
        my $version = $fw eq 'Mojo::JSON' ? Mojolicious->VERSION: $fw->VERSION;
        $json =~ s/^\[(.*)\]/$1/;
        if ($format eq 'html') {
            push @row, { type => 'json', value => $json };
        }
        else {
            push @row, $json;
        }
    }
    for my $fw (@yaml) {
        my $can = $fw->can("Dump");
        my $yaml = $can->($item);
        my $version = $fw->VERSION;
        $yaml =~ s/^---\s//;
        if ($format eq 'html') {
            push @row, { type => 'yaml', value => $yaml };
        }
        else {
            push @row, $yaml;
        }
    }
    push @rows, \@row;
    push @rows, [(' ') x @row] unless $format eq 'html';

}

if ($format eq 'text') {
    my $tb = Text::Table->new( @headers );
    $tb->load( @rows );
    print $tb;
}
elsif ($format eq 'markdown') {
    say '|', (join '|', @headers), '|';
    say '|', ('-|' x @headers);
    for my $row (@rows) {
        s/\n/<br>/g for @$row;
        say '|', (join '|', @$row), '|';
    }
}
elsif ($format eq 'html') {
    my $htc = HTML::Template::Compiled->new(
        paths => "$Bin",
        filename => "table.html",
        tagstyle => [ qw/ -asp -comment +tt / ],
        loop_context_vars => 1,
    );
    $htc->param(
        header => \@headers,
        rows => \@rows,
    );
    print $htc->output;
}
