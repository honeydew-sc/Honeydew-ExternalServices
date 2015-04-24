package Honeydew::ExternalServices;

# ABSTRACT: Helper functions for managing Honeydew's external services
use strict;
use warnings;
use POSIX qw/setsid/;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/daemonize/;

=for markdown [![Build Status](https://travis-ci.org/honeydew-sc/Honeydew-ExternalServices.svg?branch=master)](https://travis-ci.org/honeydew-sc/Honeydew-ExternalServices)

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

sub daemonize {
    chdir("/")                      || die "can't chdir to /: $!";
    open(STDIN,  "< /dev/null")     || die "can't read /dev/null: $!";
    open(STDOUT, "> /dev/null")     || die "can't write to /dev/null: $!";
    defined(my $pid = fork())       || die "can't fork: $!";
    exit if $pid;                   # non-zero now means I am the parent
    (setsid() != -1)                || die "Can't start a new session: $!";
    open(STDERR, ">&STDOUT")        || die "can't dup stdout: $!";
}

1;
