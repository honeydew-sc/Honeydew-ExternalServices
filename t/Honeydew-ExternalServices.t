use strict;
use warnings;
use Test::More;

BEGIN: {
unless (use_ok('Honeydew-ExternalServices')) {
BAIL_OUT("Couldn't load Honeydew-ExternalServices");
exit;
}
}



done_testing;
