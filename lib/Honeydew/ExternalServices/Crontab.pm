package Honeydew::ExternalServices::Crontab;

# ABSTRACT: Idempotent crontab updating
use strict;
use warnings;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/add_crontab_section remove_crontab_section/;

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
us to make sections in the crontab by using add_crontab_section.

=method add_crontab_section( $label, $section[, $crontab ] )

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

=cut

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
    return split("\n", `crontab -l`);
}

=method remove_existing_section( $label[, $crontab ] )

Takes a String C<$label>, and optionally an ArrayRef of an existing
C<$crontab>. It will run through the crontab looking for the section
denoted by the C<$label> and filter it out, returning an ArrayRef of
the filtered crontab.

If the crontab has manually inserted labels, this method will probably
screw up.

If no section is found, this is essentially a no-op.

=cut

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
