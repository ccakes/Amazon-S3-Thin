#!/usr/bin/env perl
# command tool like aws s3
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/../lib';
use Amazon::S3::Thin;
#use S3::CLI;
use Config::Tiny;

S3::CLI->new->run(@ARGV);


package S3::CLI;
use strict;
use warnings;
use Getopt::Long;
use Amazon::S3::Thin;
use Data::Dumper;

sub new {
    return bless {}, shift;
}

sub run {
    my ($self, @args) = @_;

    our $VERSION = "0.00";

    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case bundling)],
        );

    $p->getoptionsfromarray(
        \@args,
        "p|profile=s"   => \(my $profile),
        "h|help"        => \(my $help),
        "v|version"     => \(my $version),
    );
    if ($version) {
        printf "s3 %s\n", $VERSION;
        exit 0;
    }
    if ($help) {
        require Pod::Usage;
        Pod::Usage::pod2usage(0);
    }

    my $config_file = $ENV{HOME} . "/.aws/credentials";
    my $crd = Config::Tiny->read($config_file)->{$profile};
    $self->{s3client} = Amazon::S3::Thin->new($crd);
    my $subcmd = shift @args;

    #warn Dumper $subcmd, $profile , \@args;    n
    if ($subcmd eq "ls") {
        return $self->cmd_ls(@args);
    }

}

use XML::TreePP;
use JSON;

sub cmd_ls {
    my ($self, $url) = @_;
    my ($bucket, $key);
    if($url =~ m|s3://([^/]+)/(.+)$| ){
        ($bucket, $key) = ($1, $2);
        #warn "bucket, key = %s, %s\n", $bucket , $key;
    } elsif ($url =~ m|s3://([^/]+)/?$| ){
        $bucket = $1;
        #warn "bucket only = %s\n", $bucket;
    } else {
        die "bad url";
    }

    my $response = $self->{s3client}->list_objects($bucket);
    my $tpp = XML::TreePP->new();
    my $tree = $tpp->parse($response->content);

    print JSON->new->utf8->pretty->encode($tree);
}

