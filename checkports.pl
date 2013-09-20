#!/usr/bin/perl
##########################################################################
# Apache2 license
# Author: Alexander Kuehn <alex@nagilum.org>
# Purpose: This script will scan through all installed ports and run
#	   ldd against all ELF files (executeables, shared objects, etc.)
#	   it will report the port and the file of that port which has
#	   unresolved libs.
#	   PORTSDIR is assumed to be /usr/local but can be overwritten
#	   by setting it as environment variable.
#	   The output of the script can be parsed like this to 
#	   reinstall all broken ports automatically:
#	    checkports.pl|grep "=>"|awk '{print $1}'|xargs -t portupgrade -f
# Usage:   perl checkports.pl
# Notes:   The script will ignore all files in the include/ and share/locale/
#	   subdirectories to save some time.

use strict;
use Data::Dumper;
use FileHandle;
use IPC::Open2;

my $portsdir=(defined $ENV{"PORTSDIR"}) ? $ENV{"PORTSDIR"} : '/usr/local';
my %filemap;	# $file -> port
#local $|=1;
my @spinner = ('|', '/', '-', '\\');
my $count=0;
my $elfcount=0;
# first we collect all files installed by the ports
if( -r "/var/db/pkg/local.sqlite") {
	my $portname;
	for (`pkg info -al`) {
		next if(/^$/);
		if(/^\s+\//) {
			chomp;
			s/^\s+//;
			my $curfile=$_;
			next unless -f $curfile;
			open FILE, "<$curfile" || die ("error opening $curfile : $!");
			my $header;
			read FILE,$header,4;
			close FILE;
			$count++;
			if($header =~ /.ELF/) {
				if(defined $filemap{$curfile}) {
					print "$curfile is claimed by $filemap{$curfile} and $portname!\n"; 
				} else {
					$elfcount++;
					$filemap{$curfile}=$portname;
				}
				print "Collecting ELF files [$elfcount/$count] ". $spinner[$count % 4] . "\r";
			}
		} elsif(/^(\S+)\s/) {
			$portname=$1;
		}
	}
} else {
	for my $port (`find /var/db/pkg -type d -name \\\*-\\\*`) {
		chomp($port);
		my $portname=$port;
		$portname=~s/^\/var\/db\/pkg\///;
		my @content=`grep -v "^@" $port/+CONTENTS`;
		my @content2=grep(!/^include\//, @content);
		@content=grep(!/^share\/locale\//, @content2);
		@content2=();
		for (@content) {
			print "Collecting ELF files [$elfcount/$count] ". $spinner[$count % 4] . "\r";
			my $curfile="$portsdir/$_";
			chomp($curfile);
			next unless -f $curfile;
			open FILE, "<$curfile" || die ("error opening $curfile : $!");
			my $header;
			read FILE,$header,4;
			close FILE;
			$count++;
			if($header =~ /.ELF/) {
				if(defined $filemap{$curfile}) {
					print "$curfile is claimed by $filemap{$curfile} and $portname!\n"; 
				} else {
					$elfcount++;
					$filemap{$curfile}=$portname;
				}
			}
		}
	}
}
print "Collecting ELF files [$elfcount/$count] done.\n";
my $curfile;
my %failports;

$count=0;
my %already_checked;
foreach my $file (keys %filemap) {
	next if $already_checked{$file};
	$already_checked{$file}=1;
	next if("$file"=~/metasploit\/data\/john\/run.linux.x86/);
	foreach my $line (`ldd -a $file 2>/dev/null`) {
		if($line =~ /^($portsdir.*):/) {
			$curfile=$1;
			next if $already_checked{$curfile};
			$already_checked{$curfile}=1;
			print "Checking files [$count] ". $spinner[$count % 4] . "\r";
			$count++;
		} else {
			if ($line =~ /=>\ not\ found\ \(0\)$/){
				$failports{$filemap{$curfile}}=$curfile;
			}
		}
	}
}
print "Checking files [$count] done.\n";
print map {"$_ => $failports{$_}\n"} keys %failports;
