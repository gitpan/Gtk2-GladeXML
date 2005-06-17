#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/Makefile.PL,v 1.19 2005/02/08 02:43:28 muppetman Exp $
#

use strict;
use 5.008;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.1',
	'perl-ExtUtils-PkgConfig' => '1.0',
	'perl-Glib'               => '1.02', # for Glib::MakeHelper 
	'perl-Gtk2'               => '1.00',
	'Glade'                   => '2.0.0',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use Glib::MakeHelper;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too 
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => {
            Glib::                => $build_reqs{'perl-Glib'},
            Gtk2::                => $build_reqs{'perl-Gtk2'},
            ExtUtils::Depends::   => $build_reqs{'perl-ExtUtils-Depends'},
            ExtUtils::PkgConfig:: => $build_reqs{'perl-ExtUtils-PkgConfig'},
         },
   );
   exit 1; # not reached
}

our %pkgcfg = ExtUtils::PkgConfig->find ('libglade-2.0 >= '.$build_reqs{Glade});

mkdir 'build', 0777;

my $gladexml = ExtUtils::Depends->new ('GladeXML', 'Gtk2', 'Glib');
$gladexml->set_inc ($pkgcfg{cflags});
$gladexml->set_libs ($pkgcfg{libs} . $gladexml->_find_extra_libs);
$gladexml->add_pm ('GladeXML.pm' => '$(INST_LIBDIR)/GladeXML.pm');
$gladexml->add_xs ('GladeXML.xs');
my $cwd = cwd();
$gladexml->add_typemaps (map {File::Spec->catfile($cwd,$_)} 'gladexmlperl.typemap');

$gladexml->install ('gladexmlperl.h');
$gladexml->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gtk2::GladeXML',
    VERSION_FROM  => 'GladeXML.pm',
    ABSTRACT_FROM => 'GladeXML.pm',
    XSPROTOARG    => '-noprototypes',
    $gladexml->get_makefile_vars,
);


sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_rpms (
		'GLADE' => $build_reqs{'Glade'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}


# this probably needs to go into ExtUtils::Depends.
sub ExtUtils::Depends::_find_extra_libs {
	# right now we need this terrible hack only for windows.
	return "" unless $^O eq "MSWin32";

	my $self = shift;

	# win32 does not allow unresolved symbols in libraries, but
	# Gtk2 uses on symbols in the dll created for Glib.
	# so, we have to break all this nice abstraction and encapsulation
	# and find the actual Glib.dll and Glib.lib installed by perl when
	# the Glib module was built, and add it to the list of lib files.
	#
	# say it with me: "i hate win32."

	my $retstring = "";

	use File::Find;

	my %deps = $self->get_deps;
	foreach my $mod (keys %deps) {
		find (sub {
			$retstring .= " ".$File::Find::name
				if /$mod.lib/i;
		}, @INC);
	}

	return $retstring;
}
