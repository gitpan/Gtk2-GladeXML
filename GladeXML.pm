#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/GladeXML.pm,v 1.10 2003/10/10 03:54:34 muppetman Exp $
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

our $VERSION = '0.93';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::GladeXML $VERSION;

sub _connect_helper
{
	my $handler_name = shift;
	my $object = shift;
	my $signal_name = shift;
	my $signal_data = shift;
	my $connect_object = shift;
	my $after = shift;
	my $handler = shift;
	my $data = shift;

	no strict qw/refs/;

	my $func = defined($after) ? 'signal_connect_after' :
				  'signal_connect';
	if( $connect_object )
	{
		# b/c signal_connect already keeps the user_data alive
		# we don't have to worry about signal_connect_object,
		# we just pass the object in as the user_data
		$object->$func($signal_name => $handler, $connect_object);
	}
	else
	{
		$object->$func($signal_name => $handler, $signal_data);
	}
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
	if( ref $package )
	{
		$handler = sub { $package->$handler_name(@_) };
	}
	else
	{
		$handler = $package.'::'.$handler_name
			if( $package && $handler !~ /::/ );
	}

	my $func = defined($after) ? 'signal_connect_after' :
				  'signal_connect';
	if( $connect_object )
	{
		# b/c signal_connect already keeps the user_data alive
		# we don't have to worry about signal_connect_object,
		# we just pass the object in as the user_data
		$object->$func($signal_name => $handler, $connect_object);
	}
	else
	{
		$object->$func($signal_name => $handler, $signal_data);
	}

}

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

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Gtk2::GladeXML - Perl wrappers for the Gtk2::GladeXML utilities.

=head1 SYNOPSIS

  use Gtk2 -init;
  use Gtk2::GladeXML;
  
  $gladxml = Gtk2::GladeXML->new('example.glade');
  $gladexml->signal_autoconnect_from_package('main');
  $quitbtn = $gladexml->get_widget('Quit'); 
  Gtk2->main;

=head1 ABSTRACT

Provides mechinisms for instantiating and utilization of user interfaces
created with glade-2.

=head1 DESCRIPTION

Glade is open source project that provides utilities for rapid user interface
development. After designing an application with glade-2 the layout and
configuration is saved in a XML formatted file. libglade is a library to load
and use files of this particular XML format at application run time. This
module is a set of mappings of libglade. More specifically the gladexml portion
of libglade. These mappings allow access to libglade from PERL code.  Better
yet you can load a file's contents into a PERL scalar do a few magical regular
expressions to customize things and the load up the app. It doesn't get any
easier. 

=head1 FUNCTIONS

=over

=item $gladexml = Gtk2::GladeXML->new(GLADE_FILE, [ROOT, DOMAIN])

Create a new GladeXML object by loading the data in GLADE_FILE. ROOT is an
optional parameter that specifies a point (widget node) from which to start
building. DOMAIN is an optional parameter that specifies the translation domain
for the xml file.

=item $gladexml = Gtk2::GladeXML->new_from_buffer(BUFFER, [ROOT, DOMAIN])

Create a new GladeXML object from the scalar string contained in BUFFER. ROOT
is an optional parameter that specifies a point (widget node) from which to
start building. DOMAIN is an optional parameter that specifies the translation
domain for the xml file.

=item $gladexml->get_widget(NAME)

Return the widget created by the XML file with NAME or undef if no such name
exists.

=item $gladexml->signal_autoconnect_from_package(PACKAGE)

Sets up the signal handling callbacks as specified in the glade XML data.
Callbacks will need to have the exact name as specified in the XML data and be
located in the provided package (or main if none is provided.) It is worth
noting that callbacks you get for free in c such as gtk_main_quit will not
exist in perl and must always be defined, for example:

  sub gtk_main_quit
  {
  	Gtk2->main_quit;
  }

Otherwise behavior should be exactly as expected with the use of libglade from
a c application. 

=back

=head1 SEE ALSO

perl(1), Glib(1), Gtk2(1), libglade.

=head1 AUTHOR

Ross McFarland E<lt>rwmcfa1 at neces dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by the gtk2-perl team.

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
