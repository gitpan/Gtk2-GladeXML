#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/t/0.GladeXML.t,v 1.4 2003/05/22 23:21:42 rwmcfa1 Exp $
#

#########################
# GladeXML Tests
# 	- rm
#########################

#########################

use Test::More tests => 4;
BEGIN { use_ok('Gtk2::GladeXML') };

#########################

use Data::Dumper;

sub gtk_main_quit
{
	Gtk2->main_quit;
}

sub gtk_true
{
	print STDERR "gtk_true: ".Dumper( @_ );
}

sub gtk_widget_hide
{
	$_[1]->hide;
}

sub gtk_widget_show
{
	$_[1]->show;
}

ok( Gtk2->init );

ok( $gld = Gtk2::GladeXML->new('t/example.glade') );

$gld->signal_autoconnect_from_package('main');

Glib::Idle->add( sub {
	ok( $btn = $gld->get_widget("Quit") );
	$btn->activate;
	0;
});

Gtk2->main;
