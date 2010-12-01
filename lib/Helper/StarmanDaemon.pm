This mess is not ready to use.

package Catalyst::Helper::StarmanDaemon;
use strict;
use warnings;
use File::Spec;

sub mk_stuff {
    my ( $self, $helper, @args ) = @_;

    my $base = $helper->{base};
    my $app  = lc $helper->{app};

    $app =~ s/::/_/g;

    my $script = File::Spec->catfile($base, 'script', "$app.psgi");

    die "O HAI";

#    $helper->render_file('template', $script);
#    chmod 0755, $script;
}

1;

__END__

=head1 NAME

Catalyst::Helper::StarmanDaemon - Cat helper to create a starman daemon to run your psgi.

=head1 SYNOPSIS

 script/myapp_create.pl StarmanDaemon

=head1 DESCRIPTION


=head1 AUTHOR


=head1 SEE ALSO

L<Catalyst>

=cut

1;


Note, based on, thanks to... Tatsuhiko Miyagawa

__template__
#!/usr/bin/env perl
use warnings;
use strict;
use Pod::Usage;
use File::Spec;
use Path::Class qw( file dir );

my $self = file( File::Spec->rel2abs(__FILE__) );
( my ( $name ) = $self =~ m,([^/]+), ) =~ s/(?=\.)pl\z/pid/;
my $home_dir = $self->parent->parent;

# Public subs.
my %action = ( pid => \&pid,
               status => \&status,
               start => \&start,
               stop => \&stop,
               graceful => \&graceful,
               restart => \&restart,
               increment_workers => \&increment_workers,
               decrement_workers => \&decrement_workers,
               help => \&usage,
              );

my $pid_file = file("/var/run/yesh.pid");

my $workers = 10; # 5 is starman's default.

my $cmd = $action{+shift};

$cmd
   and $cmd        # Only valid commands.
   and ! @ARGV     # No extra arguments, it's misleading.
   or pod2usage(__FILE__ . " [" . join("|", sort { length($a) <=>
   length($b) } keys %action) ."]");

my $rs_dir = file( File::Spec->rel2abs(__FILE__) )->parent->parent;
my $psgi = file( $rs_dir, "script/yesh.psgi" );
my $lib = dir( $rs_dir, "lib" );
my $locallib = dir( $rs_dir, "locallib" );

$cmd->();

exit 0;

sub _pid {
   return unless -e $pid_file;
   chomp( my $pid = $pid_file->slurp );
   $pid;
}

sub pid {
   my $pid = _pid() or return;
   print "$pid\n";
}

sub _live_pid {
   my $pid = _pid() || return;
   return $pid if kill( 0 => $pid );
}

sub status {
   my $pid = _live_pid();
   print $pid ?
       "Running with pid $pid\n" : "Not running...\n";
}

sub start {
   $pid_file->remove;

   my $ok =
       0 == system(
                    "echo",
                   "starman",
                   "-I$lib",
                   "-MCatalyst",
                   "-MDBIx::Class",
# Session file issues:               "--user" => "...",
                   "--workers" => $workers,
                   "--daemonize",
                   "--pid" => $pid_file,
                   "--listen" => "localhost:10123", # needs to be an arg? Where? Default in helper.
                   $psgi
                   );

   if ( $ok )
   {
       my $pid = _live_pid() or die "$app... is in unknown state...\n";
       print "Started with pid $pid\n";
       exit(0);
   }
   else
   {
       print "Failed to start: $!!\n";
       exit(1);
   }
}

sub stop {
   my $pid =_live_pid() || die "$app is not running...\n";
   kill INT  => $pid and sleep 1;
   kill TERM => $pid and sleep 1 if kill ZERO => $pid;
   kill KILL => $pid and sleep 1 if kill ZERO => $pid;
   if ( kill ZERO => $pid )
   {
       print "Could not stop $pid\n";
       return;
   }
   else
   {
       print "Stopped\n";
       return $pid_file->remove;
   }
}

sub graceful {
   my $pid = _live_pid() || die "$app is not running...\n";
   kill HUP => $pid;
}

sub restart {
   eval { stop() };
   start();
}

sub increment_workers {
   my $pid = _live_pid() || die "$app is not running...\n";
   kill TTIN => $pid;
}

sub decrement_workers {
   my $pid = _live_pid() || die "$app is not running...\n";
   kill TTOU => $pid;
}


__END__

=pod

=head1 Usage

 $app [status|graceful|restart|stop|start|pid]

=cut
