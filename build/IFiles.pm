package GladeXML::Install::Files;

$self = {
          'inc' => '-DXTHREADS -I/home/rmcfarla/glocal/include/gtk-2.0 -I/home/rmcfarla/glocal/include/libxml2 -I/home/rmcfarla/glocal/lib/gtk-2.0/include -I/usr/X11R6/include -I/home/rmcfarla/glocal/include/atk-1.0 -I/home/rmcfarla/glocal/include/pango-1.0 -I/home/rmcfarla/glocal/include -I/usr/include/freetype2 -I/home/rmcfarla/glocal/include/glib-2.0 -I/home/rmcfarla/glocal/lib/glib-2.0/include -I/usr/include/libglade-2.0  ',
          'typemaps' => [
                          'gladexmlperl.typemap'
                        ],
          'deps' => [
                      'Glib',
                      'Gtk2'
                    ],
          'libs' => '-Wl,--export-dynamic -L/home/rmcfarla/glocal/lib -lglade-2.0 -lgtk-x11-2.0 -lxml2 -lpthread -lz -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lm -lpangoxft-1.0 -lpangox-1.0 -lpango-1.0 -lgobject-2.0 -lgmodule-2.0 -ldl -lglib-2.0  '
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/GladeXML/Install/Files.pm") {
			$CORE = $_ . "/GladeXML/Install/";
			last;
		}
	}

1;
