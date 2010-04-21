#!/usr/bin/perl -w
#
# Author: Jay Allen, Endevver LLC (http://endevver.com)


use strict;
use lib "lib", ($ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : "../../lib");

use MT;
my $mt = new MT(Config => 'mt.cfg');
use MT::Entry;
use MT::Blog;
use MT::Template;

# Check for incompatible Tags.app template tags
template_tag_check() or exit;

# Convert Tags.app entry tags to native tags
convert_entries();

# Convert Tags.app template tags to corresponding native tags
convert_templates();



sub template_tag_check {

    print "Checking for incompatible Tags.app template tags...";
    my @incompatible = qw(MTTagEntropy     MTDeliciousTag  MTFlickrTag
                          MTFeedEntryTags  MTSystemTags    MTTagGradient
                          MTTagLastUsed    MTTagQuery      MTTagSize
                          MTTagsList       MTTechnoratiTag MTTagCloud
                          );
    my $tag_pattern = '('.join('|', @incompatible).')';

    my $issues_found = 0;
    my @issues;
    # Iterate through blogs
    my $blog_iter = MT::Blog->load_iter();
    while (my $blog = $blog_iter->()) {
        # Iterate through templates
        my $template_iter = MT::Template->load_iter({ blog_id => $blog->id }, undef);
        while (my $template = $template_iter->()) {
            if ($template->text =~ m/$tag_pattern/mo) {
                my @tags = grep { $template->text =~ m/$_/m ? $_ : undef} @incompatible;
                push(@issues, {blog_name => $blog->name, blog_id => $blog->id, template => $template, tags => \@tags});
                $issues_found++;
            }
        }
    }    

    if ($issues_found) {
        print "ERROR\nERROR: One or more incompatible Tags.app template tags were found in your templates and are listed below\n";
        my $last_blog;
        foreach (@issues) { 
            if (!$last_blog or $_->{blog_name} ne $last_blog) {
                print ' BLOG: '.$_->{blog_name}."\n";
                $last_blog = $_->{blog_name};
            }
            print " \t".$_->{template}->name .':   '. join(', ', @{$_->{tags}})."\n";
        } 
        print "ABORTING Tags.app migration.  Please remove the incompatible tags and retry.\n";
    } else {
        print "OK\n"
    }
    return ! $issues_found;
}

sub convert_templates {

    my @tag_mapping = (
        # First change away from MTTag*
        {MTTagVolume         =>  'MTNativeTagRank'},
        {MTTagLink           =>  'MTNativeTagSearchLink'},
        {MTBlogTags          =>  'MTNativeTags'},  # (with some incompatible attributes)
        {MTTagCount          =>  'MTNativeTagCount'},
        # Then replace MTTag with MTTagName
        {MTTag               =>  'MTTagName'},
        # Then change the MTNativeTag* tags back to the right names
        {MTNativeTagRank     =>  'MTTagRank'},
        {MTNativeTagSearchLink => 'MTTagSearchLink'},
        {MTNativeTags        => 'MTTags'},
        {MTNativeTagCount    => 'MTTagCount'},
        # And some corrections from overzealous replacements
        {MTTagNames          => 'MTTags'},
        {MTTagNameName       => 'MTTagName'},
        {MTTagNameSearchLink => 'MTTagSearchLink'}
    );    
    print "Converting Tags.app template tags to corresponding native MT template tags:\n";
    # Iterate through blogs
    my $blog_iter = MT::Blog->load_iter();
    while (my $blog = $blog_iter->()) {
        print "\t".$blog->name."...";

        # Iterate through templates
        my $template_iter = MT::Template->load_iter({ blog_id => $blog->id }, undef);
        while (my $template = $template_iter->()) {
            my $text = $template->text;
            # print "\t\tTemplate: ".$template->name."\n";
            foreach (@tag_mapping) {                
                my ($old, $new) = (%$_);
                # print "\t\t\tConverting $old to $new\n";
                $text =~ s/$old/$new/gm;
            }
            $template->text($text);
            $template->save;
        }
       print "OK\n";
    }
    
    
}
sub convert_entries {    

    print "Converting entry tags from Tags.app to native MT tags:\n";
    # Iterate through blogs
    my $blog_iter = MT::Blog->load_iter();
    while (my $blog = $blog_iter->()) {
        print "\t".$blog->name."...";
        # Iterate through entries
       my $entry_iter = MT::Entry->load_iter({ blog_id => $blog->id }, undef);
       while (my $entry = $entry_iter->()) {
           # Convert Tags.app tags to native MT tags
           _convert_to_native_tags($entry);
       }
       print "OK\n";
    }
}

sub _convert_to_native_tags {
    my $entry = shift;
    if (my @tags = get_legacy_tags($entry)) {
        $entry->add_tags(@tags);
        $entry->keywords('');
        $entry->save or die 'Error saving entry:'.$entry->errstr."\n";
    }
}

sub get_legacy_tags {
    my ($entry) = @_;
    return unless $entry->keywords ne '';

    if ($entry and ! ref($entry)) {
        $entry = MT::Entry->load($entry);
    }
    my $k;
    $k = $entry->keywords or return '';
    my %tags;
    $k =~ s{(^\s+|\s+$)}{}sg;
    @tags{split(/\s+/, $k)} = ();

    my @tags;
    foreach my $tag (keys %tags) {
        $tag =~ s/\_/ /g;
        push(@tags, $tag);
    }
    return @tags;
}
