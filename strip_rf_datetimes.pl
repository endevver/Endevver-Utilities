#!/usr/bin/perl -w

use strict;

@ARGV || usage();
sub usage {
    $_[0] and print "$_[0]\n";
    print "Usage: ".basename($0)." CLASS\n";
    exit;
}

use Data::Dumper;
use File::Basename;
use YAML;
use lib 'extlib';
use lib 'lib';

eval {
    local $SIG{__WARN__} = sub { print "**** WARNING: $_[0]\n" };

    require MT;
    my $mt = MT->new(Config => 'mt-config.cgi') or die MT->errstr;

    require MT::PluginData;

    my $iter = MT::PluginData->load_iter({ plugin => 'rightfields' });

    while (my $pd = $iter->()) {
        my $data = $pd->data();
        my $needs_save;
        for my $field (qw(datetime1 datetime2 timestamp)) {
            if (ref($data) eq 'HASH' and exists $data->{cols} and exists $data->{cols}->{$field}) {
                print "Removing $field field from RightFields plugindata for ".$pd->key."\n";
                delete $data->{cols}->{$field};
                $pd->data($data);
                $needs_save = 1;
            }
        }
        $pd->save if $needs_save;
    }
};
if ($@) {
    print "An error occurred while loading data: $@\n";
} else {
    print "Done copying data! All went well.\n";
}

1;

__END__
