#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use JSON::PP ();
use JSON::XS ();
use Cpanel::JSON::XS ();
use Mojolicious ();
use Mojo::JSON ();
use YAML ();
use YAML::Syck ();
    $YAML::Syck::ImplicitTyping = 1;
use YAML::XS ();
use YAML::PP ();

my $a = 10;

my $b = 11;
$b .= "";

my $c = 12;
$c .= "";

my $d = 13;
my $x = $d . "string";

my $e = 14;
$e .= "";
$e += 0;

my $f = 15;
$f .= "";
$x = $f + 1;

my $g = "16";

my $h = "17";
$h += 0;

my $i = "18";
$x = $i + 0;

my $data = [
    $a,
    $b,
    $c,
    $d,
    $e,
    $f,
    $g,
    $h,
    $i,
];

for my $fw (qw/ JSON::PP JSON::XS Cpanel::JSON::XS Mojo::JSON /) {
    my $can = $fw->can("encode_json");
    my $json = $can->($data);
    my $version = $fw eq 'Mojo::JSON' ? Mojolicious->VERSION: $fw->VERSION;
    say "===== $fw $version";
    say $json;
}
for my $fw (qw/ YAML YAML::XS YAML::Syck YAML::PP /) {
    my $can = $fw->can("Dump");
    my $yaml = $can->($data);
    my $version = $fw->VERSION;
    say "===== $fw $version";
    say $yaml;
}