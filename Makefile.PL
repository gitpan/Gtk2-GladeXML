#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/Makefile.PL,v 1.2 2003/05/18 22:58:04 rwmcfa1 Exp $
#

use 5.008;
use Cwd;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Glib::PkgConfig;

%pkgcfg = Glib::PkgConfig->find ('libglade-2.0');

mkdir 'build', 0777;

$gladexml = ExtUtils::Depends->new ('GladeXML', 'Gtk2', 'Glib');
$gladexml->set_inc ($pkgcfg{cflags});
$gladexml->set_libs ($pkgcfg{libs});
$gladexml->add_pm ('GladeXML.pm' => '$(INST_LIBDIR)/GladeXML.pm');
$gladexml->add_xs ('GladeXML.xs');
$gladexml->add_typemaps (map {cwd().'/'.$_} 'gladexmlperl.typemap');
$gladexml->add_headers ('gladexmlperl.h');

$gladexml->install ('gladexmlperl.h');
$gladexml->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gtk2::GladeXML',
    VERSION_FROM  => 'GladeXML.pm',
    PREREQ_PM     => {},
    ABSTRACT_FROM => 'GladeXML.pm',
    XSPROTOARG    => '-noprototypes',
    $gladexml->get_makefile_vars,
);

#
# there's a bug in the MakeMaker output which results in .xs files in a
# subdirectory being turned into .o files in this dir.  the bug is a missing
# -o on the compiler command line.  this is a hackish fix for it.
#
package MY;
sub const_cccmd {
	my $inherited = shift->SUPER::const_cccmd (@_);
	$inherited .= ' -o $@';
	$inherited;
}
package MAIN;
