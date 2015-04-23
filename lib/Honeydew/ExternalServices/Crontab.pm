package Honeydew::ExternalServices::Crontab;

# ABSTRACT: Idempotent crontab updating
use strict;
use warnings;
use File::Basename qw/dirname/;
use Cwd qw/abs_path/;
use feature qw/say/;
use Test::More;
use Test::Deep;

# say $_ for @{ update_crontab() };

sub remove_existing_entry {
    my ($file) = @_;
    my @current_crontab = @{ _validate_args($file) };

    my @filtered = ();
    my $in_bmp_section = 0;
    foreach my $line (@current_crontab) {
        if ($line =~ /^###.*browsermob$/) {
            $in_bmp_section = !$in_bmp_section;
            next;
        }
        next if $in_bmp_section;

        push @filtered, $line;
    }

    push @filtered, '';

    return \@filtered;
}

sub add_browsermob {
    my ($file) = @_;
    my @current = @{ _validate_args($file) };

    push @current, @{ get_bmp_crontab_entry() }, "";

    return \@current;
}

sub _validate_args {
    my ($maybe_ref) = @_;
    my @array;

    if (ref($maybe_ref) eq 'ARRAY') {
        @array = @$maybe_ref;
    }
    else {
        @array = split("\n", `crontab -l`);
    }

    return \@array;
}

sub update_crontab {
    my $filtered_crontab = remove_existing_entry();
    my $updated_crontab = add_browsermob($filtered_crontab);

    return $updated_crontab;
}

1;
