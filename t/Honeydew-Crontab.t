#! /usr/bin/perl

use strict;
use warnings;
use Test::Spec;

BEGIN: {
    unless (use_ok('Honeydew::ExternalServices::Crontab')) {
        BAIL_OUT("Couldn't load Honeydew::ExternalServices::Crontab");
        exit;
    }
}

describe 'Crontab manager' => sub {
    my ($hi);
    before each => sub {
        $hi;
    };

    it 'should do things' => sub {
        $hi;
    };

};

runtests;
