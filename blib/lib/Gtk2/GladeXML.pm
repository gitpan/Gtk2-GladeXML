#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/GladeXML.pm,v 1.23 2005/01/12 02:33:55 rwmcfa1 Exp $
#
# Based strongly on gtk-perl's GladeXML
#

package Gtk2::GladeXML;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '1.003';

sub import {
	my $class = shift;
	$class->VERSION (@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

bootstrap Gtk2::GladeXML $VERSION;

sub _do_connect {
	my ($object, $signal_name, $signal_data, $connect_object,
	    $after, $handler) = @_;

	my $func = $after ? 'signal_connect_after' : 'signal_connect';
	# we get connect_object when we're supposed to call
	# signal_connect_object, which ensures that the data (an object)
	# lives as long as the signal is connected.  the bindings take
	# care of that for us in all cases, so we only have signal_connect.
	# if we get a connect_object, just use that instead of signal_data.
	$object->$func($signal_name => $handler,
		       $connect_object ? $connect_object : $signal_data);
}

# XXX used only by handler_connect, which appears to be derelict code
sub _connect_helper
{
	my $handler_name = shift;
	my $object = shift;
	my $signal_name = shift;
	my $signal_data = shift;
	my $connect_object = shift;
	my $after = shift;
	my $handler = shift;

	_do_connect ($object, $signal_name, $signal_data, $connect_object,
		     $after, $handler);
}

sub _autoconnect_helper
{
	my $handler_name = shift;
	my $object = shift;
	my $signal_name = shift;
	my $signal_data = shift;
	my $connect_object = shift;
	my $after = shift;
	my $package = shift;

	no strict qw/refs/;

	my $handler = $handler_name;
	if (ref $package) {
		$handler = sub { $package->$handler_name(@_) };
	} else {
		$handler = $package.'::'.$handler_name
			if( $package && $handler !~ /::/ );
	}

	_do_connect ($object, $signal_name, $signal_data, $connect_object,
		     $after, $handler);
}

# XXX unused code?
sub handler_connect {
	my ($self, $hname, @handler) = @_;

	$self->signal_connect_full($hname, \&_connect_helper, @handler);
}

sub signal_autoconnect_from_package
{
	my $self = shift;
	my $package = shift;

	($package, undef, undef) = caller() unless $package;
	$self->signal_autoconnect(\&_autoconnect_helper, $package);
}

sub signal_autoconnect_all {
	my ($self, %handler) = @_;
        $self->signal_autoconnect(sub {
           my $handler_name = shift;
           my $object = shift;
           my $signal_name = shift;
           my $signal_data = shift;
           my $connect_object = shift;
           my $after = shift;

           my $handler = $handler{$handler_name}
              or return;

	   _do_connect ($object, $signal_name, $signal_data, $connect_object,
			$after, $handler);
        });
}

1;
__END__

=head1 NAME

Gtk2::GladeXML - Create user interfaces directly from Glade XML files.

=head1 SYNOPSIS

  use Gtk2 -init;
  use Gtk2::GladeXML;
  
  $gladexml = Gtk2::GladeXML->new('example.glade');
  $gladexml->signal_autoconnect_from_package('main');
  $quitbtn = $gladexml->get_widget('Quit'); 
  Gtk2->main;

=head1 ABSTRACT

Gtk2::GladeXML allows Perl programmers to use libglade, a C library which
generates graphical user interfaces directly from the XML output of the
Glade user interface designer.

=head1 DESCRIPTION

Glade is a free user interface builder for GTK+ and GNOME.  After designing
a user interface with glade-2 the layout and configuration are saved in an
XML file.  libglade is a library which knows how to build and hook up the
user interface described in the Glade XML file at application run time.

This extension module binds libglade to Perl so you can create and manipulate
user interfaces in Perl code in conjunction with Gtk2 and even Gnome2.  Better
yet you can load a file's contents into a PERL scalar do a few magical regular
expressions to customize things and the load up the app. It doesn't get any
easier. 

=head1 FUNCTIONS

=over

=item $gladexml = Gtk2::GladeXML->new(GLADE_FILE, [ROOT, DOMAIN])

Create a new GladeXML object by loading the data in GLADE_FILE.  ROOT is an
optional parameter that specifies a point (widget node) from which to start
building.  DOMAIN is an optional parameter that specifies the translation
domain for the xml file.

=item $gladexml = Gtk2::GladeXML->new_from_buffer(BUFFER, [ROOT, DOMAIN])

Create a new GladeXML object from the scalar string contained in BUFFER.  ROOT
is an optional parameter that specifies a point (widget node) from which to
start building.  DOMAIN is an optional parameter that specifies the translation
domain for the xml file.

=item $widget = $gladexml->get_widget(NAME)

Return the widget created by the XML file with NAME or undef if no such name
exists.

=item $gladexml->signal_autoconnect($callback[, $userdata])

Iterates over all signals and calls the given callback:

   sub example_cb {
      my ($name, $widget, $signal, $signal_data, $connect, $after, $userdata) = @_;
   }

The following two convenience methods use this to provide a more
convenient interface.

=item $gladexml->signal_autoconnect_from_package([PACKAGE])

Sets up the signal handling callbacks as specified in the glade XML data.
Callbacks will need to have the exact name as specified in the XML data
and be located in the provided package (or the caller's package if none is
provided).  It is worth noting that callbacks you get for free in c such
as gtk_main_quit will not exist in perl and must always be defined, for
example:

  sub gtk_main_quit
  {
  	Gtk2->main_quit;
  }

Otherwise behavior should be exactly as expected with the use of libglade
from a C application.

=item $gladexml->signal_autoconnect_all (name => handler, ...)

Iterates over all named signals and tries to connect them to the handlers
specified as arguments (handlers not given as argument are being
ignored). This is very handy when implementing your own widgets, where you
can't use global callbacks.

=back

=head1 FAQ

=over

=item Where is the option to generate Perl source in Glade?

Glade itself only creates the XML description, and relies on extra converter
programs to write source code; only a few converters are widely popular.

In general, however, you don't want to generate source code for a variety of
reasons, mostly to do with maintainability.  This message on the glade-devel
list explains it best:

http://lists.ximian.com/archives/public/glade-devel/2003-February/000015.html

=back

=head1 SEE ALSO

L<perl>(1), L<Glib>(3pm), L<Gtk2>(3pm)

The Libglade Reference Manual at http://developer.gnome.org/doc/API/2.0/libglade/

=head1 AUTHOR

Ross McFarland <rwmcfa1 at neces dot com>, Marc Lehmann <pcg@goof.com>,
muppet <scott at asofyet dot org>.  Bruce Alderson provided several examples.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 by the gtk2-perl team.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

=cut
