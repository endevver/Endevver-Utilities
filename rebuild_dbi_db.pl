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
use File::Spec;
use Getopt::Long;
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
        # print YAML::Dump($data);
        my $needs_save;
        for my $field (qw(datetime1 datetime2 timestamp)) {
            if (ref($data) eq 'HASH' and exists $data->{cols} and exists $data->{cols}->{$field}) {
                print "YES!: $field - ".$data->{cols}->{$field}."\n";
                delete $data->{cols}->{$field};
                $pd->data($data);
                $needs_save = 1;
            }
        }
        $pd->save if $needs_save;
    }


    # use MT::Object;
    # my $driver = MT::Object->driver;
    # my $dbh = $driver->{dbh};
    # 
    # @CLASSES = mt_classes();
    # 
    # foreach my $class (@CLASSES) {
    #     eval "use $class";
    #     MT::Object->driver->drop_sequence($class);
    #     MT::Object->driver->create_sequence($class);
    # }

#--------------------------------------------------------
    # my $result = class_diff('blah', $class);
    # print YAML::Dump($result);
    # exit;
    # 
    # my @stmts;
    # push @stmts, $driver->fix_class($class);
    # # fix_class($driver, $class)
    # foreach my $stmt (@stmts) {
    #     my $err;
    #     $dbh->do($stmt) or $err = $dbh->errstr;
    #     if ($err) {
    #         # ignore drop errors; the table/sequence didn't exist
    #         print "failed to execute statement $stmt: $err";
    #     }
    # }
    # 
    # MT::Object->driver->drop_sequence($class);
    # MT::Object->driver->create_sequence($class);
    # print YAML::Dump(class_diff('blah', 'MT::ExtraFields'));
#--------------------------------------------------------
    # my (%args, %terms);
    # $args{'sort'} = 'id';
    # $args{direction} = 'ascend';
    # 
    # my @recs = $class->load(\%terms, \%args) or die "Error loading: ".$class->errstr."\n";
    # print YAML::Dump(\@recs);
    
};
if ($@) {
    print "An error occurred while loading data: $@\n";
} else {
    print "Done copying data! All went well.\n";
}

sub core_fix_class {
    my $self = shift;
    my (%param) = @_;

    my $class = $param{class};
    return $self->error($self->translate("Error loading class: [_1].", $class))
        unless eval 'require '.$class;

    my $result = $self->class_diff($class);
    return 1 unless $result;
    return 1 unless $result->{fix};

    my $alter = $result->{alter};
    my $add = $result->{add};
    my $drop = $result->{drop};

    my $driver = MT::Object->driver;
    my @stmts;
    push @stmts, sub { $self->pre_upgrade_class($class) };
    push @stmts, $driver->upgrade_begin($class);
    push @stmts, sub { $self->pre_create_table($class) };
    push @stmts, sub { $self->pre_add_column($class, $add) } if $add;
    push @stmts, sub { $self->pre_alter_column($class, $alter) } if $alter;
    push @stmts, sub { $self->pre_drop_column($class, $drop) } if $drop;
    push @stmts, $driver->fix_class($class);
    push @stmts, sub { $self->post_create_table($class) };
    push @stmts, sub { $self->post_add_column($class, $add) } if $add;
    push @stmts, sub { $self->post_alter_column($class, $alter) } if $alter;
    push @stmts, sub { $self->post_drop_column($class, $drop) } if $drop;
    push @stmts, $driver->upgrade_end($class);
    push @stmts, sub { $self->post_upgrade_class($class) };
    $self->run_statements($class, @stmts);
}

sub class_diff {
    my $self = shift;
    my ($class) = @_;

    return $self->error($self->translate("Error loading class: [_1].", $class))
        unless eval 'require '.$class;

    my $table = $class->datasource;
    my $defs = $class->column_defs;
print "DEFS:";
print YAML::Dump($defs);

    my $driver = MT::Object->driver;
    my $db_defs = $driver->column_defs($class);

print "DB DEFS:";
print YAML::Dump($db_defs);
    # now, compare $defs and $db_defs;
    # here are the scenarios
    #   1. we find something in $defs that isn't in $db_defs
    #      -- column should be inserted. this may trigger a process
    #   2. we find something in $db_defs that isn't in $defs
    #      -- this is a-ok. user may have added a column.
    #   3. we find a difference between $defs and $db_defs for a field
    #      a. type differs; this may trigger a process
    #      b. type is same, but null property differs; this may
    #         trigger a process
    #      c. type is same, but size differs; this may trigger a process
    #      d. key differs
    #      e. auto differs (auto-increment)
    #   4. table doesn't exist and must be created

    my $fix_class;
    $fix_class = 1 unless defined $db_defs;

    # we're only scanning defined columns; we don't care about
    # columns that are unique to the table.
    my (@cols_to_add, @cols_to_alter, @cols_to_drop);

    if (!$fix_class) {
        my @def_cols = keys %$defs;

        foreach my $col (@def_cols) {
            my $col_def = $defs->{$col};
            next if !defined $col_def;

            $col_def->{name} = $col;

            my $db_def = $db_defs->{$col};

            if (!$db_def) {
                # column is missing altogether; we're going to have to add it
                push @cols_to_add, $col_def;
            } else {
                if (($col_def->{type} eq 'string')
                 && ($db_def->{type} eq 'string')
                 && ($col_def->{size} <= $db_def->{size})) {
                    if (($col_def->{not_null} || 0) != ($db_def->{not_null} || 0)) {
                        push @cols_to_alter, $col_def;
                    }
                } elsif ($driver->type2db($col_def)
                      ne $driver->type2db($db_def)) {
                    # types are different
                    # don't bother if the database has sufficient
                    # capacity for this field
                    next if ($db_def->{type} eq 'integer')
                         && ($col_def->{type} eq 'smallint'
                          || $col_def->{type} eq 'boolean');
                    push @cols_to_alter, $col_def;
                } elsif (($col_def->{not_null} || 0) != ($db_def->{not_null} || 0)) {
                    push @cols_to_alter, $col_def;
                }
            }
        }
    }

    if ($fix_class || @cols_to_add || @cols_to_alter || @cols_to_drop) {
        my %param;
        $param{drop} = \@cols_to_drop if @cols_to_drop;
        $param{add} = \@cols_to_add if @cols_to_add;
        $param{alter} = \@cols_to_alter if @cols_to_alter;
        $param{fix} = $fix_class;
        if ((@cols_to_add && !$driver->can_add_column) ||
            (@cols_to_alter && !$driver->can_alter_column) || 
            (@cols_to_drop && !$driver->can_drop_column)) {
            $param{fix} = 1;
        }
        return \%param;
    }
    undef;
}

sub fix_class {
    my $driver = shift;
    my ($class) = @_;
    my $dbh = $driver->{dbh};

    my $db_defs = $driver->column_defs($class);

    my $exists = defined $db_defs ? 1 : 0;

    my $ds = $class->properties->{datasource};
    my $pfx = $driver->table_prefix;

    my @stmts;
    if ($exists) {
        push @stmts, "create table ${pfx}_${ds}_upgrade as select * from ${pfx}_$ds";
        push @stmts, $driver->_drop_table($class);
    }

    push @stmts, $driver->_create_table($class);

    if ($exists) {
        push @stmts, $driver->_insert_from($class, $db_defs);
    }

    push @stmts, $driver->_index_table($class);        

    # everything is cool, so drop the upgrade table
    push @stmts, "drop table ${pfx}_${ds}_upgrade" if $exists;

    @stmts;
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

__END__
