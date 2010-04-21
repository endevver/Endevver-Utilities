#!/usr/bin/perl -w
# Author: Jay Allen, Endevver LLC (http://endevver.com)

use strict;
use File::Basename;

@ARGV || usage();
sub usage {
    $_[0] and print "$_[0]\n";
    print "Usage: ".basename($0)." (rebuild|test) all\n";
    print "       ".basename($0)." (rebuild|test) CLASS[ CLASS[ CLASS...]])\n";
    print " If CLASS is used it should be a fully qualified module name (e.g. MT::Entry, MT::Tag, etc)\n";
    exit;
}

use lib 'extlib';
use lib 'lib';

eval {
    local $SIG{__WARN__} = sub { print "**** WARNING: $_[0]\n" };

    require MT;
    my $mt = MT->new(Config => 'mt-config.cgi') or die MT->errstr;

    use MT::Object;
    my $driver = MT::Object->driver;
    my $dbh = $driver->{dbh};

    my $action = shift @ARGV;
    usage("Unknown action '$action'") unless $action =~ /^(rebuild|test)$/;
    
    my @classes = (($ARGV[0]||'') eq 'all') ? mt_classes() : @ARGV;
    print ucfirst($action)."ing sequences:\n";
    foreach my $class (@classes) {
        no strict 'refs';
        &{"mode_".$action}($class);
    }
};
if ($@) {
    print "An error occurred: $@\n";
}

sub mode_rebuild {
    my $class = shift or return;
    print "  $class".('.'x(20-length($class)));
    eval "use $class";
    $@ and die $@;
    my $rc = MT::Object->driver->drop_sequence($class)
            && MT::Object->driver->create_sequence($class);
    print $rc ? "OK" : 'Error: '.(MT::Object->driver->errstr||'Unknown error');
    print "\n";
}

sub mode_test {
    my $class = shift or return;
    print "  $class".('.'x(20-length($class)));
    eval "use $class";
    $@ and die $@;
    my $defs = MT::Object->driver->column_defs($class);
    if ($defs->{id}{auto}) {        
        my $nextid = MT::Object->driver->generate_id($class);
        my $obj = $class->load($nextid);
        require Data::Dumper;
        print $obj ? "REQUIRE REBUILD!" : "OK";
        print " ($nextid)\n";
    }
    else {
        print "OK (No table sequences)\n";
    }
}

sub mt_classes {
    my @CLASSES = qw( MT::Author MT::Blog MT::Category MT::Comment MT::Entry
                      MT::IPBanList MT::Log MT::Notification MT::Permission
                      MT::Placement MT::Template MT::TemplateMap MT::Trackback
                      MT::TBPing MT::Session MT::PluginData MT::Config MT::FileInfo
                      MT::Tag MT::ObjectTag MT::Group MT::Role MT::Association
                      );
}

1;

package MT::ObjectDriver::DBI::mysql;
use strict;

sub drop_sequence { 1 }
sub create_sequence { 1 }
sub generate_id {
    my $driver = shift;
    my ($class) = @_;

    my $ds = $class->properties->{datasource};

    my $dbh = $driver->{dbh};
    return undef unless $dbh;

    my $sth = $dbh->prepare('SHOW TABLE STATUS LIKE "mt_' . $ds .'"') or return undef;
    $sth->execute or return undef;
    my $row = $sth->fetchrow_hashref;
    my $nextid = $row->{Auto_increment};
    $sth->finish;
    $nextid;
}


__END__
