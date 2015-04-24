#! /usr/bin/perl

use strict;
use warnings;

use Cwd qw/abs_path/;
use feature qw/state/;
use File::Spec;
use File::Basename qw/dirname/;
use Honeydew::ExternalServices::Crontab qw/add_crontab_section remove_crontab_section/;
use Test::Spec;
use Test::Deep;

describe 'Crontab manager' => sub {
    my ($crontab, $section);

    before each => sub {
        $crontab = load_fixture_crontab();
        $section = '* * * * * new section';
    };

    it 'should add something new to the crontab' => sub {
        my $new_crontab = add_crontab_section( 'add me', [ $section ] , $crontab );

        my $expected = [
            @$crontab,
            '',
            '### start: add me',
            $section,
            '### end: add me',
        ];

        cmp_deeply( $new_crontab, $expected);
    };

    it 'should create a crontab stub out of a label and section' => sub {
        my $stub = Honeydew::ExternalServices::Crontab::_create_crontab_stub( 'label', [ $section ] );
        cmp_deeply( $stub, [
            '### start: label',
            $section,
            '### end: label'
        ]);
    };

    it 'should move an existing label to the bottom' => sub {
        my $replaced_crontab = add_crontab_section( 'remove me', [ $section ], $crontab );

        cmp_deeply( $replaced_crontab, [
            '',
            '* * * * * ls -al',
            '',
            '# remains',
            '',
            '# blank lines',
            '',
            '### start: remove me',
            '* * * * * new section',
            '### end: remove me',
        ]);
    };

    it 'should add sections idempotently' => sub {
        my $replaced_crontab = add_crontab_section( 'remove me', [ $section ], $crontab );
        my $idempotent_crontab = add_crontab_section( 'remove me', [ $section ], $replaced_crontab );
        $idempotent_crontab = add_crontab_section( 'remove me', [ $section ], $idempotent_crontab );

        cmp_deeply( $idempotent_crontab, [
            '',
            '* * * * * ls -al',
            '',
            '# remains',
            '',
            '# blank lines',
            '',
            '### start: remove me',
            '* * * * * new section',
            '### end: remove me',
        ]);
    };

    describe 'removal' => sub {
        it 'should filter existing sections' => sub {
            my $filtered_crontab = remove_crontab_section( 'remove me', $crontab );

            cmp_deeply( $filtered_crontab, [
                '',
                '* * * * * ls -al',
                '',
                '# remains',
                '',
                '# blank lines',
                ''
            ]);
        };

        it 'should only add an empty line if the section does not exist' => sub {
            my $same_crontab = remove_crontab_section( 'missing section', $crontab );

            cmp_deeply( $same_crontab, [ @$crontab, '' ]);
        };

        it 'should remove sections idempotently' => sub {
            my $removed_crontab = remove_crontab_section( 'missing', $crontab );
            my $idempotent_crontab = remove_crontab_section( 'missing', $removed_crontab );

            cmp_deeply( $removed_crontab, $idempotent_crontab );
        };
    };

};

sub load_fixture_crontab {
    state @fixture;
    return \@fixture if scalar @fixture;

    my $fixture_filename = File::Spec->catfile(
        abs_path( dirname(__FILE__) ),
        'fixtures/crontab'
    );

    open (my $fh, '<', $fixture_filename);
    @fixture = map { chomp; $_ } <$fh>;
    close ($fh);

    return \@fixture;
}

runtests;
