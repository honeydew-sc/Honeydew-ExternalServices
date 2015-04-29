package Honeydew::ExternalServices;
$Honeydew::ExternalServices::VERSION = '0.03';
# ABSTRACT: Helper functions for managing Honeydew's external services
use strict;
use warnings;
use POSIX qw/setsid/;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/daemonize/;


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

__END__

=pod

=encoding UTF-8

=head1 NAME

Honeydew::ExternalServices - Helper functions for managing Honeydew's external services

=for markdown [![Build Status](https://travis-ci.org/honeydew-sc/Honeydew-ExternalServices.svg?branch=master)](https://travis-ci.org/honeydew-sc/Honeydew-ExternalServices)

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/honeydew-sc/Honeydew-ExternalServices/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
