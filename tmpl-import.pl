#!/usr/binperl -w
use strict;
use lib '../lib';
use File::Basename;

sub usage {
    $_[0] and print STDERR "Error: $_[0]\n";
    print STDERR "Usage: ".basename($0)." FILE BLOGID\n";
#     print STDERR <<EOD;
#     --dump      Load objects from databaase and export to YAML files.
#     --load      Load objects from YAML files and import into database
#     --init      Initialize the database tables and proceed as with --load
#     --datadir   The path to the YAML import/export directory
#     --file      The name/path of a YAML import/export file, good for 
#                 single class actions.
#     --class     Limits actions to only this class.  Option can be specified repeatedly.
#     --notclass  Excludes actions to specified class.  Option can be specified repeatedly.
#     --help      Show this message
# EOD
    exit;
}

use MT::Bootstrap;
use MT;
my $mt = MT->new(Config=>'../mt-config.cgi');

use MT::Template;

my ($file,$blog_id) = @ARGV;
usage("Missing arguments") unless $file && $blog_id;

my $data = read_tmpl($file);

my $VAR1;
eval $data;

my @tmpls = @$VAR1;

map { $_->remove } MT::Template->load({blog_id=>$blog_id, type=>'index'});

for my $t (@tmpls) { 
    my $x = MT::Template->load({blog_id=>$blog_id, name=>$t->name});
    $x ||= MT::Template->new;
    $x->set_values($t->column_values);
    $x->blog_id($blog_id);
    $x->save;
}

sub read_tmpl {
	my $name = shift;
	open my $file, $name or die "Cannot read '$name': $!\n";
	my $text = do { local $/; <$file> };
	chomp  $text;
	return $text;
}

# see rsync for ideas
# overwrite (non-overwrite should be default)
# mappings???
