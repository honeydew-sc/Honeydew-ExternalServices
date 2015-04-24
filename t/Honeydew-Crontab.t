#! /usr/bin/perl

use strict;
use warnings;

use Cwd qw/abs_path/;
use File::Spec;
use File::Basename qw/dirname/;
use Honeydew::ExternalServices::Crontab qw/add_crontab_section remove_crontab_section/;
use Test::Spec;
use Test::Deep;


describe 'Crontab manager' => sub {
    my ($crontab, $section);
    my $fixture_filename = File::Spec->catfile(
        abs_path( dirname(__FILE__) ),
        'fixtures/crontab'
    );

    open (my $fh, '<', $fixture_filename);
    my @fixture = map { chomp; $_ } <$fh>;
    close ($fh);

    before each => sub {
        $crontab = \@fixture;
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

    it 'should remove an existing section from a crontab' => sub {
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



};

runtests;
