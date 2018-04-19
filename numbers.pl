#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

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

my @headers = ('', '', qw/ INT FLOAT STRING /, @json, @yaml);
my @rows;
my $i = 0;
my @versions = ('','','','','');
for my $fw (@json, @yaml) {
    my $version = $fw eq 'Mojo::JSON' ? Mojolicious->VERSION: $fw->VERSION;
    push @versions, $version;
}
push @rows, \@versions;


for my $i (0 .. $#data) {
    my $item = $data[ $i ];
    my $code = $codes[ $i ] // '-';
#    Devel::Peek::Dump $item;
    my $flags = B::svref_2object(\$item)->FLAGS;
    my $intflag = $flags & B::SVp_IOK ? 1 : '';
    my $floatflag = $flags & B::SVp_NOK ? 1 : '';
    my $stringflag = $flags & B::SVp_POK ? 1 : '';

    my @row;
    push @row, $i++;
    push @row, $code;
    push @row, $intflag, $floatflag, $stringflag;
    for my $fw (@json) {
        my $can = $fw->can("encode_json");
        my $json = $can->([$item]);
        my $version = $fw eq 'Mojo::JSON' ? Mojolicious->VERSION: $fw->VERSION;
        $json =~ s/^\[(.*)\]/$1/;
        push @row, $json;
    }
    for my $fw (@yaml) {
        my $can = $fw->can("Dump");
        my $yaml = $can->($item);
        my $version = $fw->VERSION;
        $yaml =~ s/^---\s//;
        push @row, $yaml;
    }
    push @rows, \@row;
    push @rows, [(' ') x @row];

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
