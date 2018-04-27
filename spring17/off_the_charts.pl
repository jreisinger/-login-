#!/usr/bin/perl
use strict;
use warnings;

use DBI qw(:sql_types);
use File::Listing;

# ls -lR . > ls.out
my $file = shift;

open my $L, '<', $file or die "Can't open $file:$!\n";
my $dir = File::Listing::parse_dir( $L, undef, 'unix', 'warn' );
close $L;

my $dbh = DBI->connect( "dbi:SQLite:dbname=$file.db", "", "" );

$dbh->{RaiseError} = 1;
$dbh->{AutoCommit} = 0;

$dbh->do(
    "CREATE TABLE dir (filename text, filetype text, filesize
    integer, filetime integer, filemode text)"
);

my $sth = $dbh->prepare(
    "INSERT INTO dir (filename, filetype, filesize, filetime,
    filemode) VALUES (?,?,?,?,?)"
);

my $rowcount = 0;
foreach my $listing (@$dir) {
    $sth->execute(@$listing);
    if ( $rowcount++ % 1000 == 0 ) {
        $dbh->commit;
        print STDERR ".";
    }
}

$dbh->commit;
$dbh->disconnect;
