#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/Makefile.PL,v 1.13 2003/10/10 03:54:34 muppetman Exp $
#

use 5.008;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.1',
	'perl-ExtUtils-PkgConfig' => '0.1',
	'perl-Glib'               => '1.00',
	'perl-Gtk2'               => '1.00',
	'Glade'                   => '2.0.0',
);

# minimum required version of dependancies we need to run
our %runtime_reqs = (
	'Glade'	=> undef,
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends;"
           . "use ExtUtils::PkgConfig;"
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

%pkgcfg = ExtUtils::PkgConfig->find ('libglade-2.0 >= '.$build_reqs{Glade});

$runtime_reqs{Glade} = $pkgcfg{modversion};

mkdir 'build', 0777;

$gladexml = ExtUtils::Depends->new ('GladeXML', 'Gtk2', 'Glib');
$gladexml->set_inc ($pkgcfg{cflags});
$gladexml->set_libs ($pkgcfg{libs});
$gladexml->add_pm ('GladeXML.pm' => '$(INST_LIBDIR)/GladeXML.pm');
$gladexml->add_xs ('GladeXML.xs');
my $cwd = cwd();
$gladexml->add_typemaps (map {File::Spec->catfile($cwd,$_)} 'gladexmlperl.typemap');
$gladexml->add_headers ('gladexmlperl.h');

$gladexml->install ('gladexmlperl.h');
$gladexml->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gtk2::GladeXML',
    VERSION_FROM  => 'GladeXML.pm',
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
use Cwd;

sub const_cccmd {
	my $inherited = shift->SUPER::const_cccmd (@_);
	$inherited .= ' -o $@';
	$inherited;
}

sub postamble
{
	my @dirs = qw{rpms rpms/BUILD rpms/RPMS rpms/SOURCES
		      rpms/SPECS rpms/SRPMS};
	my $cwd = getcwd();
	
	my %subs = (
		'VERSION' => '$(VERSION)',
		'SOURCE' => '$(DISTNAME)-$(VERSION).tar.gz',
		'GLADE_RUN' => $runtime_reqs{'Glade'},
		'GLADE' => $build_reqs{'Glade'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	);
	
	my $substitute = '$(PERL) -npe \''.join('; ', map {
			"s/\\\@$_\\\@/$subs{$_}/g";
		} keys %subs).'\'';

	"
realclean ::
	-\$(RM_RF) build perl-\$(DISTNAME).spec

rpms/:
	-mkdir @dirs

SUBSTITUTE=$substitute

perl-\$(DISTNAME).spec: perl-\$(DISTNAME).spec.in \$(VERSION_FROM) Makefile
	\$(SUBSTITUTE) \$< > \$@

dist-rpms: Makefile dist perl-\$(DISTNAME).spec rpms/
	cp \$(DISTNAME)-\$(VERSION).tar.gz rpms/SOURCES/
	rpmbuild -ba --define \"_topdir $cwd/rpms\" perl-\$(DISTNAME).spec
"
}
package MAIN;
