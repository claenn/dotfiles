#!/usr/bin/perl -w
# vim: si sw=4 ts=4 et tw=78:
#
# mkdir_heute - choose or make a dir for 'heute' (today)
#
# This script scans a basedir (~/archiv) for directories named YYYY/MM/DD
# where YYYY, MM and DD are numbers corresponding to a year, month, day of
# month. You may choose a directory from the list or a new directory which
# will be created named after the current day.
#
# The script returns the choosen directory on STDOUT and may be used in a
# shell alias like this:
#
# alias cdheute='cd `mkdir_heute`'
#
# so that you may say 'cdheute' on the command line and your working directory
# will be changed to the choosen directory.
#
use strict;

$|++;

my $basedir   = "$ENV{HOME}/archiv";
my $listLines = 20;

my ($day,$month,$year) = (localtime)[3,4,5];

$day   = sprintf("%02d",$day);
$month = sprintf("%02d",$month+1);
$year += 1900;

my $daydir    = "$year/$month/$day";
my $dirprefix = "$basedir/$daydir";

$listLines -= 2; # reserve one line for '+' and 'q'

print chooseDir($basedir,$daydir);

sub makeDir {
    my $path = shift;
    my $dir  = '';
    $path =~ s{^(.*[^/])$}{$1/}; # provide a sentinel
    while ($path =~ s{^([^/]*)/}{}) {
        if ($1) {
            $dir .= $1;
            (-d $dir) || mkdir($dir,0777) || return 0;
            $dir .= '/';
        }
        else {
            $dir = '/' unless ($dir);
        }
    }
    return 1;
} # makeDir()

sub chooseDir {
    my ($basedir,$daydir)  = @_;
    my ($base,$prefix,$relbase);

    my @dirs     = findDirs( $basedir, $listLines );
    my @projects = findProjects( $basedir, @dirs);

    # let the user choose a directory
    my $suffix = '';
    while ( 1 ) {
        my $project_text = '';
        for (my $i = 1; $i <= $#dirs; $i++) {
            my $project = $projects[$i] || '';
            printf STDERR "%-7s: %-12s: %s\n", $i, $dirs[$i], $project;
        }
        print STDERR "+(plus): neues Verzeichnis\n";
        print STDERR "q      : aktuelles Verzeichnis\n";
        $suffix = <STDIN>;
        chomp $suffix;
        if ($suffix =~ /^(\.|q(uit)?)$/i) {
            return '.';
        }
        elsif ($suffix =~ /^\+(.*)$/) {
            if ($1) {
                $project_text = $1;
                $project_text =~ s/^\s+//;
                $project_text =~ s/\s+$//;
            }
            $suffix = q();
            if (-d $dirprefix) {
                $suffix = 'a';
                while (-d qq($dirprefix$suffix)) {
                    $suffix++;
                }
            }
            if (makeDir($dirprefix . $suffix)) {
                if ($project_text
                   and open(my $PROJ,'>',qq($dirprefix$suffix/.project))) {
                    print $PROJ qq($project_text\n);
                }
                return $dirprefix . $suffix;
            }
            else {
                return '.';
            }
        }
        elsif ( $suffix =~ /^\d+$/ ) {
            return qq($basedir/$dirs[$suffix]) if ( $dirs[$suffix] );
        }
    }
} # chooseDir()

sub findDirs {
    my ($basedir,$listLines) = @_;
    my @dirs    = ();
    my $dirNum  = 1;

    # find the last $list_lines daily directories under $BASEDIR
    if ( my @years = getDirList( $basedir, qr(^\d{4}$) ) ) {

        YEAR:
        for my $year (reverse sort @years) {

            my @months = getDirList( qq($basedir/$year)
                                   , qr(^\d{2}$)
                                   );

            next YEAR unless @months;

            MONTH:
            for my $month (reverse sort @months) {

                my @days = getDirList( qq($basedir/$year/$month)
                                     , qr(^\d{2})
                                     );

                next MONTH unless @days;

                # iterate over all days of this month backward
                DAY:
                for my $day (reverse sort @days) {

                    my $path = qq($year/$month/$day);
                    $dirs[$dirNum] = $path;
                    $dirNum++;

                    # no need to search for more directories
                    last YEAR if ($dirNum > $listLines);
                }
            }
        }
    }
    @dirs;
} # findDirs()

sub findProjects {
    my ($basedir,@dirs) = @_;
    my @projects = ();
    my $dirNum   = 0;

    for my $path ( @dirs ) {
        if ($path and -f qq($basedir/$path/.project)
           and open my $PROJECT, '<', qq($basedir/$path/.project)) {
            my $project = <$PROJECT>;
            close $PROJECT;
            chomp $project;
            $projects[$dirNum] = $project;
        }
        $dirNum++;
    }
    return @projects;
} # findProjects()

sub getDirList {
    my ($basedir,$regex) = @_;
    my @dirList = ();

    if (opendir my $BASEDIR, $basedir) {

        while (defined (my $dir = readdir($BASEDIR))) {
            if ($dir =~ m/$regex/) {
                push @dirList, $dir;
            }
        }
        closedir $BASEDIR;
    }
    return @dirList;
} # getDirHash()
