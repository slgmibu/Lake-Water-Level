#!/usr/bin/perl -w
use strict;
use warnings; 

use Data::Dumper;
use HTML::TokeParser;
use MIME::Lite::TT::HTML;
use WWW::Mechanize;
use YAML::XS qw(LoadFile);

### Load Configuration File
open my $configFile, '<', 'conf/config.yaml' or die "can't open config file: $!";
my $config = LoadFile($configFile);
#print Dumper $config;

### Scrape Lake Thurmond elevation
my $url = $config->{'url'};
my $agent = WWW::Mechanize->new();
$agent->get($url);

my $stream = HTML::TokeParser->new(\$agent->{content});
my $done = 0;
my $elevation = 0;

while($stream->get_tag("tr") and not $done) {
    $stream->get_tag("td");
    my $firstCellText = $stream->get_trimmed_text("/td");
#    print "$firstCellText\n";
    if ($firstCellText =~ m/THURMOND LAKE/) {
        $stream->get_tag("td"); # Station ID
        $stream->get_tag("td"); # Flood Level (feet)
        $stream->get_tag("td"); # Summer Level (feet)
        $stream->get_tag("td"); # 7am Pool Elev (ft)
        $elevation = $stream->get_trimmed_text("/td");
        print "$elevation\n";
        $done = 1;
    }
}

### Send elevation in an email
my %params; 
$params{first_name} = "Mirko";
$params{elevation}  = $elevation;
$params{url}  = $url;
 
my %options; 
$options{INCLUDE_PATH} = 'tt'; 

my $msg = MIME::Lite::TT::HTML->new( 
    From        =>  'mirko.bulovic@nokia.com',
    To          =>  'lake-thurmond-water-level-watch@googlegroups.com',
    Subject     =>  'Lake Thurmond Water Level', 
    Template    =>  {
            text    =>  'mail.text.en.tt',
            html    =>  'mail.html.en.tt',
    },
    TmplOptions =>  \%options, 
    TmplParams  =>  \%params, 
);

#$msg->send('smtp','localhost', Debug=>0 );
$msg->send_by_smtp('smtp', $config->{'smtpServer'}, AuthUser=>$config->{'smtpServerUsername'}, AuthPass=>$config->{'smtpServerPassword'}, Auth=>'NTLM', Debug=>1);

