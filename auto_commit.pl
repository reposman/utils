#!/usr/bin/perl -w
use strict;
use Cwd qw/getcwd/;
use File::Spec;
my @subrepos = ('svn','git' );#,'git/privepo');
my $hooks = 'hooks.pl';
my $update_script = 'git/update_modified.pl';
my $commit_script = 'commit.pl';
my @pargs;
my @cargs;
while(@ARGV) {
	$_ = shift @ARGV;
	if(m/(?:--master|--force|--mirror|--tags)/) {
		push @pargs,$_;
	}
	elsif($_ eq '--append') {
		my $what = shift(@ARGV);
		push @pargs,$_,$what;
	}
	else {
		push @cargs,$_;
	}
}

sub run {
	print STDERR " :",join(" ",@_),"\n";
	return system(@_) == 0;
}
sub select_prog {
	my $name = shift;
	my $dir = shift;
	my $cwd = getcwd();
	foreach my $d ($cwd,"scripts",$dir) {
		my $prog = File::Spec->catfile($d,$name);
		if(-f $prog) {
			return $prog;
		}
	}
	return undef;
}
my $cwd = getcwd();
my $scriptdir = File::Spec->rel2abs($0,$cwd);#;#ARGV[0];
(undef,$scriptdir,undef) = File::Spec->splitpath($scriptdir);
print STDERR "Current working directory: $cwd\n";
print STDERR "Use script directory: $scriptdir\n";
foreach(@subrepos) {
	print STDERR "Entering [$_] ...";
	if(!chdir($_)) {
		print STDERR "\t[Error: $!]\n";
		goto LAST;
	}
	print STDERR "\n";
	print STDERR "Updating [$_] ...";
	my $prog = select_prog($hooks,$scriptdir);
	if($prog) {
		print STDERR "\n";
		run("perl",$prog,$update_script,@pargs);
	}
	else {
		print STDERR "\t[Error: Command not found]\n";
	}
LAST:
	print STDERR "Leaving [$_] ...\n";
	chdir($cwd);
}
print STDERR "Commiting ...\n";
run('perl',select_prog($commit_script,$scriptdir),@cargs);

