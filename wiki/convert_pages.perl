# a script to convert existing pages to a new format, where each page is a
# directory, and each file under that directory is a property.

do 'common.perl';
do 'pages.perl';

# override env var, just to make things easier
# this is the _dest_ directory; we'll be using put_page to write the new
# pages.
$pagedir = "newpages";
$oldpagedir = "oldpages";

sub run_svn {
    my @svn = ("$svn", @_);
    system(@svn) == 0 or die "can't run @svn: $!";
}

# Convert a page name (in CamelCase) to a directory name, with underscores
# separating the wiki words - so CamelCase becomes Camel_Case.
sub nicer_name {
    my ($name) = @_;
    my $nicer = fancy_title($name);
    $nicer =~ tr/ /_/;   # replace space with _
    return "$nicer";
}

sub get_old_page {
    my ($pagename) = @_;
    my %page = (
        name        => nicer_name("$pagename"),
        exists      => 0,
        text        => "",
        modtime     => 0,
        editcomment => ""
    );
    my $f = "$oldpagedir/$pagename";
    if (-r "$f" && -f "$f") {
        $page{'exists'} = 1;
        $page{'text'} = read_file("$f");
        $page{'modtime'} = int(`svn pg modtime $f`);
        chomp($page{'editcomment'} = `svn pg editcomment $f`);
    }
    return %page;
}

sub doit {
    opendir PAGES, "$oldpagedir" or die "can't opendir $oldpagedir: $!";
    foreach my $pagename (grep { ! m/^\./ } readdir PAGES) {
        my %p = get_old_page($pagename);
        print "$p{'modtime'} $p{'name'} $p{'editcomment'}\n";
        put_page(%p) if $p{'exists'} = 1;
    }
    closedir PAGES;
    return @matches;
}

doit();

