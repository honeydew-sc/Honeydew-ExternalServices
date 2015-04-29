package Honeydew::ExternalServices::Crontab;
$Honeydew::ExternalServices::Crontab::VERSION = '0.03';
# ABSTRACT: Idempotent crontab management
use strict;
use warnings;
use Cwd qw/abs_path/;
use File::Basename qw/dirname/;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/add_file_to_crontab add_crontab_section remove_crontab_section/;


sub add_crontab_section {
    my ($label, $section, $crontab) = @_;
    $crontab //= _get_existing_crontab();

    my $filtered_crontab = remove_crontab_section( $label, $crontab );
    my $labeled_section = _create_crontab_stub( $label, $section );
    my $appended_crontab = [ @$filtered_crontab, @$labeled_section ];

    return $appended_crontab;
}

sub _create_crontab_stub {
    my ($label, $section) = @_;

    my $header = '### start: ' . $label;
    my $footer = '### end: '   . $label;

    return [ $header, @$section, $footer ];
}

sub _get_existing_crontab {
    return [ split("\n", `crontab -l`) ];
}


sub add_file_to_crontab {
    my ($label, $file, $crontab) = @_;

    my $section = _interpolate(
        _read_file($file),
        $file
    );

    return add_crontab_section( $label, $section, $crontab );
}

sub _read_file {
    my ($filename) = @_;

    open (my $fh, '<', $filename);
    my (@file) = <$fh>;
    close ($fh);

    # trim newlines, as we're putting everything in arrays
    @file = map { chomp; $_ } @file;

    return \@file;
}

sub _interpolate {
    my ($contents, $file) = @_;

    my $abs_file = abs_path($file);
    my $here_dir = abs_path(dirname($abs_file));

    my @crontab = ();
    foreach my $line (@$contents) {
        $line =~ s/__DIR__/$here_dir/;
        push @crontab, $line;
    }

    return \@crontab;
}


sub remove_crontab_section {
    my ($label, $crontab) = @_;
    $crontab //= _get_existing_crontab();

    my @filtered = ();
    my $in_section = 0;
    foreach my $line (@$crontab) {
        if ($line =~ /^### start: $label/) {
            $in_section = 1;
        }
        elsif ($line =~ /^### end: $label/) {
            $in_section = 0;
            next;
        }

        if ($in_section) {
            next;
        }
        else {
            push @filtered, $line;
        }
    }

    # Crontabs need an empty line at the end to be valid.
    if ($filtered[-1] ne '') {
        push @filtered, '';
    }

    return \@filtered;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Honeydew::ExternalServices::Crontab - Idempotent crontab management

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In add-to-crontab.pl:

    my $new_crontab = add_crontab_section( 'label', [ '# section' ] );
    say $_ for @$new_crontab;

Meanwhile,

    # test to see what the output will look like
    $ add-to-crontab.pl

    # update the crontab
    $ crontab add-to-crontab.pl

=head1 DESCRIPTION

We need a bunch of different services for Honeydew and Kabocha to
run. They all want to put things in the crontab. This module enables
us to make sections in the crontab by using L</add_crontab_section>
and L</add_file_to_crontab. See also C<bin/hd-crontab>.

=head1 METHODS

=head2 add_crontab_section( $label, $section[, $crontab ] )

Takes a String C<$label>, an ArrayRef of a new C<$section>, and
optionally an ArrayRef of an existing C<$crontab>.

Returns an ArrayRef of a crontab with the section at the end. If the
section matches a label that was already in the crontab, it will be
removed, and the new <$section> will be added to the end of the
resulting ArrayRef.

The label will be used in a comment to denote sections like such:

    ### start: label
    * * * * * ls -al
    ### end: label

The section will be inserted between the labels.

This method is idempotent.

=head2 add_file_to_crontab ( $label, $file[, $crontab ] )

This is the main driver of the C<hd-crontab> command. It takes a
String C<$label> for your section, the String C<$file> to find it in,
and optionally (primarily for testing) an existing ArrayRef
C<$crontab> to append it to.

It returns an ArrayRef of the crontab with the contents of C<$file>
appended to the end in the C<$label> section.

=head2 remove_existing_section( $label[, $crontab ] )

Takes a String C<$label>, and optionally an ArrayRef of an existing
C<$crontab>. It will run through the crontab looking for the section
denoted by the C<$label> and filter it out, returning an ArrayRef of
the filtered crontab.

If the crontab has manually inserted labels, this method will probably
screw up.

If no section is found, this is essentially a no-op.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Honeydew::ExternalServices|Honeydew::ExternalServices>

=back

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
