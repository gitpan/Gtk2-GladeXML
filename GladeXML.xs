/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/GladeXML.xs,v 1.7 2003/07/01 01:25:04 rwmcfa1 Exp $
 *
 * Based strongly on gtk-perl's GladeXML
 * 
 */

#include "gladexmlperl.h"

/* see glade_set_custom_handler for what this is */
static AV *custom_args = NULL;
#define PackCallbackST(av, first)							\
		if (SvRV(ST(first)) && (SvTYPE(SvRV(ST(first))) == SVt_PVAV)) {		\
			int i;								\
			AV * x = (AV*)SvRV(ST(first));					\
			for(i=0;i<=av_len(x);i++) {					\
				av_push(av, newSVsv(*av_fetch(x, i, 0)));		\
			}								\
		} else {								\
			int i;								\
			for(i=first;i<items;i++)					\
				av_push(av, newSVsv(ST(i)));				\
		}

static void
connect_func_handler (const gchar *handler_name,
		      GObject     *object,
		      const gchar *signal_name,
		      const gchar *signal_data,
		      GObject     *connect_object,
		      gboolean     after,
		      gpointer     user_data)
{
	AV *av;
	SV *handler;
	dSP;

	/*
	g_printerr("connect_many (%s, %p, %s, %s, %p, %d, %p\n",
		   handler_name, object, signal_name, signal_data,
		   connect_object, after, user_data);
	*/

#define IF_NULL_SET_EMPTY(var) \
	if( !(var) )		\
		(var) = "";
	IF_NULL_SET_EMPTY(handler_name);
	IF_NULL_SET_EMPTY(signal_name);
	IF_NULL_SET_EMPTY(signal_data);
#undef IF_NULL_SET_EMPTY

	av = (AV*)user_data;
	handler = *av_fetch(av, 0, 0);

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs(sv_2mortal(newSVpv(handler_name, 0)));
	XPUSHs(sv_2mortal(newSVGtkObject(object)));
	XPUSHs(sv_2mortal(newSVpv(signal_name, 0)));
	XPUSHs(sv_2mortal(newSVpv(signal_data, 0)));
	if( connect_object )
		XPUSHs(sv_2mortal(newSVGtkObject(connect_object)));
	else
		XPUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
	XPUSHs(sv_2mortal(newSViv(after)));
	XPUSHs(sv_2mortal(newSVsv(*av_fetch(av, 1, 0))));

	PUTBACK;

	perl_call_sv(handler, G_DISCARD);

	FREETMPS;
	LEAVE;


}

static GtkWidget*
glade_custom_widget (GladeXML *xml, gchar *func_name, char* name, char* string1, char* string2, int int1, int int2, gpointer data) {
	SV * s;
	SV *handler;
	int i;
	GtkWidget *result;
	dSP;

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	if (!name) name = "";
	if (!func_name) func_name = "";
	if (!string1) string1 = "";
	if (!string2) string2 = "";

	XPUSHs(sv_2mortal(newSVGtkObject(GTK_OBJECT(xml))));
	XPUSHs(sv_2mortal(newSVpv(func_name, strlen(func_name))));
	XPUSHs(sv_2mortal(newSVpv(name, strlen(name))));
	XPUSHs(sv_2mortal(newSVpv(string1, strlen(string1))));
	XPUSHs(sv_2mortal(newSVpv(string2, strlen(string2))));
	XPUSHs(sv_2mortal(newSViv(int1)));
	XPUSHs(sv_2mortal(newSViv(int2)));

	for (i=1;i<=av_len(custom_args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(custom_args, i, 0))));
	PUTBACK;

	handler = *av_fetch(custom_args, 0, 0);
	i=perl_call_sv(handler, G_SCALAR);
	SPAGAIN;
	if (i != 1)
		croak("create_custom_widget2 failed");
	s = POPs;
	result = (GtkWidget*)SvGtkObject(s);
	PUTBACK;
	FREETMPS;
	LEAVE;
	return result;
}

MODULE = Gtk2::GladeXML	PACKAGE = Gtk2::GladeXML	PREFIX = glade_xml_

BOOT:
	gperl_register_object (GLADE_TYPE_XML, "Gtk2::GladeXML");

##  GladeXML *glade_xml_new (const char *fname, const char *root, const char *domain)
GladeXML_ornull *
glade_xml_new (class, fname, root=NULL, domain=NULL)
	SV         *class
	const char *fname
	const char *root
	const char *domain
    C_ARGS:
	fname, root, domain

##  GladeXML *glade_xml_new_from_buffer (const char *buffer, int size, const char *root, const char *domain)
GladeXML_ornull *
glade_xml_new_from_buffer (class, buffer, root=NULL, domain=NULL)
	SV         *class
	SV         *buffer
	const char *root
	const char *domain
    PREINIT:
	int   len;
	char *p;
    CODE:
    	p = SvPV(buffer, len);
	RETVAL = glade_xml_new_from_buffer(p, len, root, domain);
    OUTPUT:
	RETVAL

##  gboolean glade_xml_construct (GladeXML *self, const char *fname, const char *root, const char *domain)
#gboolean
#glade_xml_construct (self, fname, root, domain)
#	GladeXML   *self
#	const char *fname
#	const char *root
#	const char *domain

##  void glade_xml_signal_connect (GladeXML *self, const char *handlername, GCallback func)
#void
#glade_xml_signal_connect (self, handlername, func)
#	GladeXML   *self
#	const char *handlername
#	GCallback   func

##  void glade_xml_signal_connect_data (GladeXML *self, const char *handlername, GCallback func, gpointer user_data)
#void
#glade_xml_signal_connect_data (self, handlername, func, user_data)
#	GladeXML    *self
#	const char *handlername
#	GCallback   func
#	gpointer    user_data

## probably shouldn't use this unless you know what you're doing
##  void glade_xml_signal_autoconnect (GladeXML *self)
void
glade_xml_signal_autoconnect (self, func, user_data=NULL)
	GladeXML *self
	SV       *func
	SV       *user_data
    PREINIT:
    	AV *av;
    CODE:
	av = newAV();
    	av_push(av, newSVsv(func));
    	av_push(av, newSVsv(user_data));
	glade_xml_signal_autoconnect_full(self, connect_func_handler, 
					  (gpointer)av);

## probably shouldn't use this unless you know what you're doing
##  void glade_xml_signal_connect_full (GladeXML *self, const gchar *handler_name, GladeXMLConnectFunc func, gpointer user_data)
void
glade_xml_signal_connect_full (self, handler_name, func, user_data)
	GladeXML            *self
	const gchar         *handler_name
	SV                  *func
	SV                  *user_data
    PREINIT:
    	AV *av;
    CODE:
	av = newAV();
    	av_push(av, newSVsv(func));
    	av_push(av, newSVsv(&PL_sv_undef));
    	glade_xml_signal_connect_full(self, handler_name, connect_func_handler, 
				      (gpointer)av);

##  void glade_xml_signal_autoconnect_full (GladeXML *self, GladeXMLConnectFunc func, gpointer user_data)
#void
#glade_xml_signal_autoconnect_full (self, func, user_data)
#	GladeXML            *self
#	GladeXMLConnectFunc  func
#	gpointer             user_data

##  GtkWidget *glade_xml_get_widget (GladeXML *self, const char *name)
GtkWidget_ornull *
glade_xml_get_widget (self, name)
	GladeXML   *self
	const char *name

##  GList *glade_xml_get_widget_prefix (GladeXML *self, const char *name)
void
glade_xml_get_widget_prefix (self, name)
	GladeXML   *self
	const char *name
    PREINIT:
	GList * widgets = NULL;
	GList * i = NULL;
    PPCODE:
	widgets = glade_xml_get_widget_prefix(self, name);
	if( !widgets )
		XSRETURN_EMPTY;
	for( i = widgets; i != NULL; i = i->next )
		XPUSHs(sv_2mortal(newSVGtkWidget(i->data)));
	g_list_free(widgets);

## probably shouldn't use this unless you know what you're doing
##  gchar *glade_xml_relative_file (GladeXML *self, const gchar *filename)
gchar *
glade_xml_relative_file (self, filename)
	GladeXML    *self
	const gchar *filename

MODULE = Gtk2::GladeXML	PACKAGE = Gtk2::Glade	PREFIX = glade_

## probably shouldn't use these unless you know what you're doing

##  void glade_set_custom_handler(GladeXMLCustomWidgetHandler handler, gpointer user_data)
void
glade_set_custom_handler (class, handler, ...)
	SV *     class
	SV *     handler
    CODE:
	if( custom_args )
	{
		SvREFCNT_dec((SV*)custom_args);
		custom_args = NULL;
	}
	if( handler )
	{
		custom_args = newAV();
		PackCallbackST(custom_args,1);
		glade_set_custom_handler(glade_custom_widget, NULL);
	}

MODULE = Gtk2::GladeXML	PACKAGE = Gtk2::Widget	PREFIX = glade_

## const char *glade_get_widget_name      (GtkWidget *widget);
const char *
glade_get_widget_name (widget)
	GtkWidget *widget

##  GladeXML *glade_get_widget_tree (GtkWidget *widget)
GladeXML *
glade_get_widget_tree (widget)
	GtkWidget *widget

