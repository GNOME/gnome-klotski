/* -*- mode:C; indent-tabs-mode: nil; tab-width: 8; c-basic-offset: 2; -*- */

/* 
 *   Gnome Klotski: Klotski clone
 *   Written by Lars Rydlinge <lars.rydlinge@hig.se>
 * 
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


#include <config.h>
#include <gnome.h>
#include <string.h>
#include <libgnomeui/gnome-window-icon.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include "pieces.h"

#define APPNAME "gnotski"
#define APPNAME_LONG "GNOME Klotski"

#define TILE_SIZE 34

#define RELEASE 4
#define PRESS 3
#define MOVING 2
#define UNUSED 1
#define USED 0

GtkWidget *window;
GtkWidget *statusbar;
GtkWidget *space;
GtkWidget *move_value;

GdkPixmap *buffer = NULL;
GdkPixbuf *tiles_pixmap = NULL;

char *map = NULL;
char *tmpmap = NULL;
char *move_map = NULL;
char *orig_map = NULL;

gint height = -1, 
  width = -1, 
  moves = 0;

gint session_flag = 0;
gint session_xpos = 0;
gint session_ypos = 0;
gint session_position = 0;

char current_level[16];

void create_window (void);
void create_space (void);
void create_statusbar (void);

GdkColor *get_bg_color (void);
void redraw_all (void);
void message (gchar *);
void load_image (void);
void gui_draw_pixmap (char *, gint, gint);
gint get_piece_nr (char *, gint, gint);
gint get_piece_id (char *, gint, gint);
void set_piece_id (char *, gint, gint, gint);
gint check_valid_move (gint, gint, gint);
gint do_move_piece (gint, gint, gint);
gint move_piece (gint, gint, gint, gint, gint);
void copymap (char *, char *);
gint mapcmp (char *, char *);
static gint save_state (GnomeClient *, gint, GnomeRestartStyle, gint,
                        GnomeInteractStyle, gint fast, gpointer);
void print_map (char *);
void set_move (gint);
void new_move (void);
gint game_over (void);
void game_score (void);

/* ------------------------- MENU ------------------------ */
void new_game_cb (GtkWidget *, gpointer);
void quit_game_cb (GtkWidget *, gpointer);
void level_cb (GtkWidget *, gpointer);
void about_cb (GtkWidget *, gpointer);
void score_cb (GtkWidget *, gpointer);

GnomeUIInfo level_1_menu[] = {
  { GNOME_APP_UI_ITEM, N_("1"), NULL, level_cb,
    "1#10#11#" \
    "          " \
    "          " \
    "  ######  " \
    "  #a**b#  " \
    "  #a**b#  " \
    "  #cdef#  " \
    "  #ghij#  " \
    "  #k  l#  " \
    "  ##--##  " \
    "        .." \
    "        ..", 
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("2"), NULL, level_cb,
    "2#10#11#" \
    "          " \
    "          " \
    "  ######  " \
    "  #a**b#  " \
    "  #a**b#  " \
    "  #cdef#  " \
    "  #cghi#  " \
    "  #j  k#  " \
    "  ##--##  " \
    "        .." \
    "        ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("3"), NULL, level_cb,
    "3#10#11#" \
    "          " \
    "          " \
    "  ######  " \
    "  #a**b#  " \
    "  #a**b#  " \
    "  #cdde#  " \
    "  #fghi#  " \
    "  #j  k#  " \
    "  ##--##  " \
    "        .." \
    "        ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("4"), NULL, level_cb,
    "4#10#11#" \
    "          " \
    "          " \
    "  ######  " \
    "  #a**b#  " \
    "  #a**b#  " \
    "  #cdef#  " \
    "  #cghf#  " \
    "  #i  j#  " \
    "  ##--##  " \
    "        .." \
    "        ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("5"), NULL, level_cb,
    "5#10#11#" \
    "          " \
    "          " \
    "  ######  " \
    "  #a**b#  " \
    "  #a**b#  " \
    "  #cdde#  " \
    "  #cfgh#  " \
    "  #i  j#  " \
    "  ##--##  " \
    "        .." \
    "        ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("6"), NULL, level_cb,
    "6#10#11#" \
    "          " \
    "          " \
    "  ######  " \
    "  #a**b#  " \
    "  #a**b#  " \
    "  #cdde#  " \
    "  #cfge#  " \
    "  #h  i#  " \
    "  ##--##  " \
    "        .." \
    "        ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("7"), NULL, level_cb,
    "7#10#7#" \
    "..        " \
    ".         " \
    "  #####-- " \
    "  #**aab- " \
    "  #*ccde# " \
    "  #fgh  # " \
    "  ####### " ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

/* Tile Mismatch
  { GNOME_APP_UI_ITEM, N_("8"), NULL, level_cb,
    "8#13#11#" \
    "  ########## " \
    "  #a**bcccd# " \
    "  #ee*bfghi# " \
    "  #j****klm# " \
    "  #opq**rst# " \
    "  #uvw     - " \
    "  #######--- " \
    "         ..  " \
    "          .  " \
    "         ...." \
    "           .." ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL }, */
   GNOMEUIINFO_END
};

GnomeUIInfo level_2_menu[] = {

  { GNOME_APP_UI_ITEM, N_("1"), NULL, level_cb,
    "11#10#9#" \
    "         a" \
    " #######  " \
    " #**bbc#  " \
    " #defgh#  " \
    " #ijkgh-  " \
    " #llk  #  " \
    " #######  " \
    "         m" \
    "  ..      " ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },


  { GNOME_APP_UI_ITEM, N_("2"), NULL, level_cb,
    "12#10#10#" \
    "          " \
    "  ######  " \
    "  #abc*#  " \
    "  # dd*#  " \
    "  # ee*#  " \
    "  # fgh#  " \
    "  ##-###  " \
    "        . " \
    "        . " \
    "        . ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("3"), NULL, level_cb,
    "13#10#11#" \
    "        .." \
    "        . " \
    " ####-- . " \
    " #ab  -   " \
    " #ccd #   " \
    " #ccd #   " \
    " #**ee#   " \
    " #*fgh#   " \
    " #*iih#   " \
    " ######   " \
    "          ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("4"), NULL, level_cb,
    "14#10#7#" \
    "  ########" \
    "  -aabc  #" \
    "  #aabdef#" \
    "  #ijggef#" \
    "  #klhh**#" \
    "  ########" \
    "        .." ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("5"), NULL, level_cb,
    "15#10#9#" \
    " .        " \
    "..        " \
    "  #--#### " \
    "  #  aab# " \
    "  # cdfb# " \
    "  -hcefg# " \
    "  #hijk*# " \
    "  #hll**# " \
    "  ####### ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("6"), NULL, level_cb,
    "16#10#8#" \
    "  ######  " \
    "  #abcd#  " \
    "  #**ee#  " \
    "  #f*g #  " \
    "  #fh i-  " \
    "  ####--  " \
    "        .." \
    "         .",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

   /* Tiles mismatch
  { GNOME_APP_UI_ITEM, N_("7"), NULL, level_cb,
    "14#13#11#" \
    "         ... " \
    "          .  " \
    " ########    " \
    " #abcdde-    " \
    " #ffcddg-    " \
    " #hhijkl#    " \
    " #***jml#    " \
    " #n*op q#    " \
    " #nrr s #    " \
    " ########    " \
    "             ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL }, */

  { GNOME_APP_UI_ITEM, N_("7"), NULL, level_cb,
    "17#10#8#" \
    " ######## " \
    " #abcc**# " \
    " #ddeef*# " \
    " #ddghfi# " \
    " -   jki# " \
    " #--##### " \
    "       .. " \
    "        . ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

   GNOMEUIINFO_END
};

GnomeUIInfo level_3_menu[] = {

  { GNOME_APP_UI_ITEM, N_("1"), NULL, level_cb,
    "21#19#19#" \
    ".aaaaaaaaaaaaaaaaab" \
    "..  cddeffffffffffb" \
    " .. cddeffffffffffb" \
    "  . cddeffffffffffb" \
    "ggg-############hhb" \
    "ggg-  ABCDEFFGH#hhb" \
    "ggg-       FFIJ#hhb" \
    "ggg#       KLMJ#hhb" \
    "ggg#NNNNOOOPQMJ#hhb" \
    "ggg#NNNNOOOP*RS#hhb" \
    "ggg#TTTTTUVW**X#hhb" \
    "ggg#YZ12222W3**#hhb" \
    "ggg#YZ12222W34*#iib" \
    "jjj#YZ155555367#klb" \
    "jjj#############mmb" \
    "jjjnooooooooooppppb" \
    "jjjqooooooooooppppb" \
    "       rrrssssppppb" \
    "ttttttuvvvvvvvwwwwx",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("2"), NULL, level_cb,
    "22#11#10#" \
    " ######### " \
    " #abbb***# " \
    " #abbb*c*# " \
    " #adeefgg# " \
    " #  eefhh# " \
    " #    ihh# " \
    " #    ihh# " \
    " #---##### " \
    "       ... " \
    "       . . ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  /* Tiles mismatch
  { GNOME_APP_UI_ITEM, N_("X"), NULL, level_cb,
    "14#20#12#" \
    "a     bbbbbb  cccccc" \
    "a     bbbbbb  cccccc" \
    "a   -##-#######     " \
    "    -AAAAABBCC#     " \
    "   d-   DEFGHI#     " \
    "    #   DEFGJI#     " \
    "  e #   KEFGLI#     " \
    "  e #   KEFG*I#     " \
    "    #   MM****#     " \
    "fff ###########     " \
    "fff  ggghhhiiiii  .j" \
    "kkkkkggg   iiiii....",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL }, 
   */

  { GNOME_APP_UI_ITEM, N_("3"), NULL, level_cb,
    "23#13#11#" \
    "ABBBBBBBBBBBB" \
    "AC          D" \
    "AC######### D" \
    " C#**abbcc# D" \
    " C#**abbdd# D" \
    "EC#eefgh  # D" \
    "EC#iiijk  -FZ" \
    "E #iiijk  -IG" \
    "E #########IG" \
    "EHHHH     ..G" \
    "EHHHHJJJJJ..G",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("4"), NULL, level_cb,
    "24#11#11#" \
    " ABCCCCCCCC" \
    " ABCCCCCCCC" \
    " A####### D" \
    "EE#aab**# D" \
    "EE#aabc*# D" \
    "EE-defgg# D" \
    "  #  fhh# D" \
    "  #  ihh# D" \
    "  #--#### D" \
    "..FF      D" \
    " .FFGGGGGGD",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("5"), NULL, level_cb,
    "25#8#10#" \
    ".       " \
    ".       " \
    " #-#### " \
    " # abc# " \
    " # dec# " \
    " #fggc# " \
    " #fhhi# " \
    " #fjk*# " \
    " #flk*# " \
    " ###### ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("6"), NULL, level_cb,
    "26#12#12#" \
    " ########## " \
    " #a*bcdefg# " \
    " #**bhhhhg# " \
    " #*iijjkkg# " \
    " #liimnoop# " \
    " #qiirrr  # " \
    " #qstuvv  # " \
    " #qwwxvv  # " \
    " ######--## " \
    "           ." \
    "          .." \
    "          . ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

   GNOMEUIINFO_END
};

GnomeUIInfo game_menu[] = {
  { GNOME_APP_UI_SUBTREE, N_("_Novice"), NULL, level_1_menu,  NULL,NULL,
    GNOME_APP_PIXMAP_STOCK, NULL, 
    (GdkModifierType) 0, GDK_CONTROL_MASK },
  { GNOME_APP_UI_SUBTREE, N_("_Medium"), NULL, level_2_menu,  NULL,NULL,
    GNOME_APP_PIXMAP_STOCK, NULL, 
    (GdkModifierType) 0, GDK_CONTROL_MASK },
  { GNOME_APP_UI_SUBTREE, N_("_Advanced"), NULL, level_3_menu,  NULL,NULL,
    GNOME_APP_PIXMAP_STOCK, NULL,
    (GdkModifierType) 0, GDK_CONTROL_MASK },
  GNOMEUIINFO_MENU_SCORES_ITEM (score_cb, NULL),
  GNOMEUIINFO_SEPARATOR,
  GNOMEUIINFO_MENU_QUIT_ITEM (quit_game_cb, NULL),
  GNOMEUIINFO_END
};

GnomeUIInfo help_menu[] = {
  GNOMEUIINFO_HELP ("gnotski"), 
  GNOMEUIINFO_MENU_ABOUT_ITEM (about_cb, NULL),
  GNOMEUIINFO_END
};

GnomeUIInfo main_menu[] = {
  GNOMEUIINFO_MENU_GAME_TREE (game_menu),
  GNOMEUIINFO_MENU_HELP_TREE (help_menu),
  GNOMEUIINFO_END
};

static const struct poptOption options[] = {
  { NULL, 'x', POPT_ARG_INT, &session_xpos, 0, NULL, NULL },
  { NULL, 'y', POPT_ARG_INT, &session_ypos, 0, NULL, NULL },
  { NULL, '\0', 0, NULL, 0 }
};

/* ------------------------------------------------------- */

int 
main (int argc, char **argv)
{
  GnomeClient *client;

  gnome_score_init (APPNAME);
  bindtextdomain (GETTEXT_PACKAGE, GNOMELOCALEDIR);
  bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
  textdomain (GETTEXT_PACKAGE);
   
  gnome_program_init (APPNAME, VERSION,
                       LIBGNOMEUI_MODULE,
                       argc, argv,
                       GNOME_PARAM_POPT_TABLE, options,
                       GNOME_PARAM_APP_DATADIR, DATADIR, NULL);
  gnome_window_icon_set_default_from_file (GNOME_ICONDIR"/gnotski-icon.png");
  client = gnome_master_client ();
  g_object_ref (G_OBJECT (client));
  gtk_object_sink (GTK_OBJECT (client));
  
  g_signal_connect (G_OBJECT (client), "save_yourself", 
                    G_CALLBACK (save_state), argv[0]);
  g_signal_connect (G_OBJECT (client), "die",
                    G_CALLBACK (quit_game_cb), argv[0]);

  create_window ();
  gnome_app_create_menus (GNOME_APP (window), main_menu);
  load_image ();
  create_space (); 
  create_statusbar ();

  if (session_xpos >= 0 && session_ypos >= 0)
    gtk_window_move (GTK_WINDOW (window), session_xpos, session_ypos);
    
  gtk_widget_show_all (window);
  new_game_cb (space, NULL);
  
  gtk_main ();
  
/*  gtk_object_unref(GTK_OBJECT(client)); */
  return 0;
}

GdkColor *
get_bg_color (void) 
{
  GtkStyle *style;
  GdkColor *color;
  style = gtk_widget_get_style (space);
  color = gdk_color_copy (&style->bg[GTK_STATE_NORMAL]);
  return color;
}

void
create_window (void)
{
  window = gnome_app_new (APPNAME, N_(APPNAME_LONG));
  gtk_window_set_resizable (GTK_WINDOW (window), FALSE);
  gtk_widget_realize (window);
  g_signal_connect (GTK_OBJECT (window), "delete_event", 
                    GTK_SIGNAL_FUNC (quit_game_cb), NULL);
}

static gint
expose_space (GtkWidget *widget, GdkEventExpose *event)
{
  if (buffer == NULL)
    return FALSE;

  gdk_draw_drawable (widget->window, 
                     widget->style->fg_gc[GTK_WIDGET_STATE(widget)], 
                     buffer, event->area.x, event->area.y, 
                     event->area.x, event->area.y, 
                     event->area.width, event->area.height);
  return FALSE; 
}

void
redraw_all (void)
{
  gint x, y;
  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++)
      gui_draw_pixmap (map, x, y);
}

static gint
movable (gint id)
{
  if(! (id == '#' || id == '.' || id == ' ' || id == '-'))
     return 1;
  return 0;
}

gint button_down = 0;
gint piece_id = -1;
gint piece_x = 0; 
gint piece_y = 0; 

static gint
button_press_space (GtkWidget *widget, GdkEventButton *event)
{
  if (event->button == 1) {
    if (game_over ())
      return FALSE;
    button_down = 1;
    piece_x = (gint) event->x / TILE_SIZE;
    piece_y = (gint) event->y / TILE_SIZE;
    piece_id = get_piece_id (map, piece_x, piece_y); 
    copymap (move_map, map);
  }
  return FALSE;
}

static gint
button_release_space (GtkWidget *widget, GdkEventButton *event)
{
  if (event->button == 1) {
    if (button_down == 1) {
      if (movable (piece_id))
	if (mapcmp (move_map, map)) {
	  new_move ();
	  if (game_over ()) {
	    message (_("Level completed. Well done."));
	    game_score ();
	  }
	}
      button_down = 0;
    }
  }
  return FALSE;
}

static gint
button_motion_space (GtkWidget *widget, GdkEventButton *event)
{ 
  gint new_piece_x, new_piece_y;
  if (button_down == 1) {
    new_piece_x = (gint) event->x / TILE_SIZE;
    new_piece_y = (gint) event->y / TILE_SIZE;
    if (new_piece_x >= width || event->x < 0
        || new_piece_y >= height || event->y < 0) 
      return FALSE;
    if (movable (piece_id))
      if (move_piece (piece_id, piece_x, piece_y, new_piece_x, new_piece_y) == 1) {
	piece_x = new_piece_x;
        piece_y = new_piece_y;
      }
    return TRUE;
  }
  return FALSE;
}

void
gui_draw_pixmap (char *target, gint x, gint y)
{
  GdkGC *gc;
  GdkColor *bg_color;
  GtkStyle *style;
  GdkColor *fg_color;
  gint value;

  gc = space->style->black_gc;

  style = gtk_widget_get_style (space);
  fg_color = &style->fg[GTK_STATE_NORMAL];

  /* blank background */
  bg_color = get_bg_color ();
  gdk_gc_set_foreground (gc, bg_color);
  gdk_color_free (bg_color);
  gdk_draw_rectangle (buffer, gc, TRUE,
                      x * TILE_SIZE, y * TILE_SIZE,
                      TILE_SIZE, TILE_SIZE);
  gdk_gc_set_foreground (gc, fg_color);

  gdk_draw_pixbuf (buffer, gc, tiles_pixmap,
                   get_piece_nr (target, x, y) * TILE_SIZE, 0, 
                   x * TILE_SIZE, y * TILE_SIZE,
                   TILE_SIZE, TILE_SIZE,
                   GDK_RGB_DITHER_NORMAL, 0, 0);

  if (get_piece_id (target, x, y) == '*') {
    if (get_piece_id (orig_map, x, y) == '.')
      value = 20;
    else
      value = 22;
    gdk_draw_pixbuf (buffer, gc, tiles_pixmap,
                     value * TILE_SIZE + 10, 10,
                     x * TILE_SIZE + 10, y * TILE_SIZE + 10, 8, 8,
                     GDK_RGB_DITHER_NORMAL, 0, 0);
  }

  gtk_widget_queue_draw_area (space, x * TILE_SIZE, y * TILE_SIZE,
                              TILE_SIZE, TILE_SIZE);
}

static void
show_score_dialog (gint pos)
{
  GtkWidget *dialog;

  dialog = gnome_scores_display (_(APPNAME_LONG), APPNAME, current_level, pos);
  if (dialog != NULL) {
    gtk_window_set_transient_for (GTK_WINDOW (dialog), GTK_WINDOW (window));
    gtk_window_set_modal (GTK_WINDOW (dialog), TRUE);
  }
}

void
score_cb (GtkWidget *widget, gpointer data)
{
  show_score_dialog (0);
}

static void
update_score_state (void)
{
  gchar **names = NULL;
  gfloat *scores = NULL;
  time_t *scoretimes = NULL;
  gint top;
  
  top = gnome_score_get_notable (APPNAME, current_level,
                                 &names, &scores, &scoretimes);
  if (top > 0) {
    gtk_widget_set_sensitive (game_menu[3].widget, TRUE);
    g_strfreev (names);
    g_free (scores);
    g_free (scoretimes);
  } else {
    gtk_widget_set_sensitive (game_menu[3].widget, FALSE);
  }
}

void
game_score ()
{
  gint pos;
  pos = gnome_score_log (moves, current_level, FALSE);
  update_score_state ();
  show_score_dialog (pos);
}

static gint
configure_space (GtkWidget *widget, GdkEventConfigure *event)
{
  if (width > 0) {
    if (buffer)
      g_object_unref (buffer);
    buffer = gdk_pixmap_new (widget->window, widget->allocation.width, 
                             widget->allocation.height, -1);
    redraw_all ();
  }
  return TRUE;
}

void
create_space (void)
{
  gtk_widget_push_colormap (gdk_rgb_get_colormap ());
  space = gtk_drawing_area_new ();
  gtk_widget_pop_colormap ();
  gnome_app_set_contents (GNOME_APP (window), space);
  gtk_widget_set_events (space, GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK
                         | GDK_POINTER_MOTION_MASK | GDK_BUTTON_RELEASE_MASK);
  gtk_widget_realize (space);
  g_signal_connect (G_OBJECT (space), "expose_event", 
                    G_CALLBACK (expose_space), NULL);
  g_signal_connect (G_OBJECT (space), "configure_event", 
                    G_CALLBACK (configure_space), NULL);
  g_signal_connect(G_OBJECT(space), "button_press_event", 
                   G_CALLBACK (button_press_space), NULL);
  g_signal_connect (G_OBJECT(space),"button_release_event",
                    G_CALLBACK (button_release_space), NULL);
  g_signal_connect (G_OBJECT(space), "motion_notify_event",
                    G_CALLBACK (button_motion_space), NULL);
  gtk_widget_show (space);
}

void
create_statusbar (void)
{
  GtkWidget *move_label, *move_box;

  move_box = gtk_hbox_new (FALSE, 0);
  move_label = gtk_label_new (_("Moves:"));
  gtk_box_pack_start (GTK_BOX (move_box), move_label, FALSE, FALSE, 6);
  move_value = gtk_label_new ("000");
  gtk_box_pack_start (GTK_BOX (move_box), move_value, FALSE, FALSE, 6);

  statusbar = gnome_appbar_new (FALSE, TRUE, GNOME_PREFERENCES_USER);
  gtk_box_pack_end (GTK_BOX (statusbar), move_box, FALSE, FALSE, 0);
  gnome_app_set_statusbar (GNOME_APP (window), statusbar);

  /*gnome_app_install_menu_hints (GNOME_APP (window), main_menu);*/
}

void
message (gchar *message)
{
  gnome_appbar_pop (GNOME_APPBAR (statusbar));
  gnome_appbar_push (GNOME_APPBAR (statusbar), message);
}

void
load_image (void)
{
  char *fname;

  fname = gnome_program_locate_file (NULL, GNOME_FILE_DOMAIN_APP_PIXMAP, 
                                     "gnotski.png", FALSE, NULL);
  if (g_file_test (fname, G_FILE_TEST_EXISTS)) {
    tiles_pixmap = gdk_pixbuf_new_from_file (fname, NULL);
  } else {
    GtkWidget *dialog;

    dialog = gtk_message_dialog_new (NULL,
                                     GTK_DIALOG_MODAL,
                                     GTK_MESSAGE_ERROR,
                                     GTK_BUTTONS_OK,
                                     _("Could not find \'%s\' pixmap file\n"),
                                     fname);
    gtk_dialog_run (GTK_DIALOG (dialog));

    exit (1);
  }
  g_free (fname);
}

void
set_move (gint x)
{
  moves = x - 1;
  new_move ();
}

void
new_move (void)
{
  gchar *str = NULL;
  if (moves < 999)
    moves++;
  str = g_strdup_printf ("%03d", moves);
  gtk_label_set_text (GTK_LABEL (move_value), str);
  g_free (str);
}

void
print_map (char *src)
{
  gint x, y;
  for (y = 0; y < height; y++) {
    for (x = 0; x < width; x++)
      printf ("%c", get_piece_id (src, x, y));
    printf ("\n");
  }
}

int
game_over (void)
{
  gint x, y, over = 1;
  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++)
      if (get_piece_id (map, x, y) == '*'
          && get_piece_id (orig_map, x, y) != '.')
	over = 0;
  return over;
}

gint
do_move_piece (gint id, gint dx, gint dy)
{
  gint x, y;
  copymap (tmpmap, map);

  /* Move pieces */
  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++)
      if (get_piece_id (tmpmap, x, y) == id)
	set_piece_id (tmpmap, x, y, ' ');

  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++)
      if (get_piece_id (map, x, y) == id)
	set_piece_id (tmpmap, (x+dx), (y+dy), id);

  /* Preserve some from original map */
  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++){
      if (get_piece_id (tmpmap, x, y) == ' '
          && get_piece_id (orig_map, x, y) == '.')
	set_piece_id (tmpmap, x, y, '.');
      if (get_piece_id (tmpmap, x, y) == ' '
          && get_piece_id (orig_map, x, y) == '-')
	set_piece_id (tmpmap, x, y, '-');
    }
  /* Paint changes */
  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++)
      if (get_piece_id (map, x, y) != get_piece_id (tmpmap, x, y)
          || get_piece_id (tmpmap, x, y) == id)
	gui_draw_pixmap (tmpmap, x, y);

  copymap (map, tmpmap);
  return 1;
}

gint
check_valid_move (gint id, gint dx, gint dy)
{
  gint x, y, valid = 1;

  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++)
      if (get_piece_id (map, x, y) == id)
	if (!(get_piece_id (map, x + dx, y + dy) == ' '
              || get_piece_id (map, x + dx, y + dy) == '.'
              || get_piece_id (map, x + dx, y + dy) == id
              || (id == '*' && get_piece_id (map, x + dx, y + dy) == '-'))) {
	  valid = 0;
	}
  return valid;
}

gint
move_piece (gint id, gint x1, gint y1, gint x2, gint y2)
{
  gint return_value = 0;

  if (get_piece_id (map, x2, y2) == id)
    return_value = 1;

  if (! ((abs (y1 - y2) == 0
          && abs (x1 - x2) == 1)
         || (abs (x1 - x2) == 0
             && abs (y1 - y2) == 1)))
    return 0;

  if (abs (y1 - y2) == 1) {
    if (y1 - y2 < 0) 
      if (check_valid_move (id, 0, 1))
	return do_move_piece (id, 0, 1);
    if (y1 - y2 > 0) 
      if (check_valid_move (id, 0, -1))
	return do_move_piece (id, 0, -1);
  }
  if (abs (x1 - x2) == 1) {
    if (x1 - x2 < 0) 
      if (check_valid_move (id, 1, 0))
	return do_move_piece (id, 1, 0);
    if (x1 - x2 > 0) 
      if (check_valid_move (id, -1, 0))
	return do_move_piece (id, -1, 0);
  }
  return return_value;
}

gint
get_piece_id (char *src, gint x, gint y)
{
  return src[x + 1 + (y + 1) * (width + 2)];
}

void
set_piece_id (char *src, gint x, gint y, gint id)
{
  src[x + 1 + (y + 1) * (width + 2)] = id;
}


gint
get_piece_nr (char *src, gint x, gint y)
{
  char c;
  gint i = 0, nr = 0;
  x++;
  y++;
  c = src[x + y * (width + 2)];
  if (c == '-') return 23;
  if (c == ' ') return 21;
  if (c == '.') return 20;

  nr += 1   * (src[(x - 1) + (y - 1) * (width + 2)] == c);
  nr += 2   * (src[(x - 0) + (y - 1) * (width + 2)] == c);
  nr += 4   * (src[(x + 1) + (y - 1) * (width + 2)] == c);
  nr += 8   * (src[(x - 1) + (y - 0) * (width + 2)] == c);
  nr += 16  * (src[(x + 1) + (y - 0) * (width + 2)] == c);
  nr += 32  * (src[(x - 1) + (y + 1) * (width + 2)] == c);
  nr += 64  * (src[(x - 0) + (y + 1) * (width + 2)] == c);
  nr += 128 * (src[(x + 1) + (y + 1) * (width + 2)] == c);
  while (nr != image_map[i] && image_map[i] != -1) 
    i += 2;
  return image_map[i + 1];
}

gint
mapcmp (char *m1, char *m2)
{
  gint x, y;
  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++)
      if (get_piece_id (m1, x, y) != get_piece_id (m2, x, y))
	return 1;
  return 0;
}

void
copymap (char *dest, char *src)
{
  memcpy (dest, src, (width + 2) * (height + 1));
}

static void
prepare_map (char *level)
{
  gint x, y, i = 0;
  static gint first = 1;
  char tmp[32];
  char *p = level;

  if (p == NULL) {
    if (first) {
      p = \
	".  ddjk ." \
	"  **  hh " \
	" **      " \
	" *  ggff " \
	" **   ff " \
	"  **  ff " \
	".  eeiff.";
      width = 9;
      height = 7;
      first = 0;
      message (_("Welcome to GNOME Klotski"));
    } else {
      return;
    }
  } else {
    while (i < 16 && *p != '#')
      current_level[i++] = *p++;
    current_level[i] = '\0';
    p++;
    
    i = 0; 
    while (i < 16 && *p != '#')
      tmp[i++] = *p++;
    tmp[i] = '\0'; 
    width = atoi (tmp);
    p++;
    
    i = 0; 
    while (i < 16 && *p != '#')
      tmp[i++] = *p++;
    tmp[i] = '\0'; 
    height = atoi (tmp);
    p++;
    
    sprintf (tmp, _("Playing level %s"), current_level);
    
    message (tmp);
  }

  if (map) {
    free (map);
    free (tmpmap);
    free (move_map);
    free (orig_map);
  }

  map = calloc (1, (width + 2) * (height + 2));
  tmpmap = calloc (1, (width + 2) * (height + 2));
  orig_map = calloc (1, (width + 2) * (height + 2));
  move_map = calloc (1, (width + 2) * (height + 2));
  if (p != NULL)
    for (y = 0; y < height; y++)
      for (x = 0; x < width; x++)
	set_piece_id (map, x, y, *p++);
  copymap (orig_map, map);
}


void
new_game_cb (GtkWidget *widget, gpointer data)
{
  widget = space;

  prepare_map (data);
  gtk_widget_set_size_request (GTK_WIDGET (space),
                               width * TILE_SIZE, height * TILE_SIZE);
  gtk_widget_realize (window);

  set_move (0);

  update_score_state ();
}

void
quit_game_cb (GtkWidget *widget, gpointer data)
{
  if (buffer)
    g_object_unref (buffer);
  if (tiles_pixmap)
    g_object_unref (tiles_pixmap);

  gtk_main_quit ();
}

static gint
save_state (GnomeClient *client, gint phase, 
            GnomeRestartStyle save_style, gint shutdown,
            GnomeInteractStyle interact_style, gint fast,
            gpointer client_data)
{
  gchar *argv[20];
  gint i;
  gint xpos, ypos;
  
  gdk_window_get_origin (window->window, &xpos, &ypos);
  
  i = 0;
  argv[i++] = (gchar *)client_data;
  argv[i++] = "-x";
  argv[i++] = g_strdup_printf ("%d", xpos);
  argv[i++] = "-y";
  argv[i++] = g_strdup_printf ("%d", ypos);
  
  gnome_client_set_restart_command (client, i, argv);
  gnome_client_set_clone_command (client, 0, NULL);
  
  g_free (argv[2]);
  g_free (argv[4]);
  return TRUE;
}

void
level_cb (GtkWidget *widget, gpointer data)
{
  new_game_cb (space, data);
}

void
about_cb (GtkWidget *widget, gpointer data)
{
  GdkPixbuf *pixbuf = NULL;
  static GtkWidget *about = NULL;
  
  const gchar *authors[] = { "Lars Rydlinge", NULL };
  gchar *documenters[] = { "Andrew Sobala (andrew@sobala.net)", NULL };
  /* Translator credits */
  gchar *translator_credits = _("translator-credits");

  if (about != NULL) {
    gtk_window_present (GTK_WINDOW (about));
    return;
  }
  {
    char *filename = NULL;
    
    filename = gnome_program_locate_file (NULL,
                                          GNOME_FILE_DOMAIN_APP_PIXMAP,
                                          ("gnotski-icon.png"),
                                          TRUE, NULL);
    if (filename != NULL)
      {
        pixbuf = gdk_pixbuf_new_from_file(filename, NULL);
        g_free (filename);
      }
  }
  
  about = gnome_about_new (_(APPNAME_LONG), VERSION, 
                           "Copyright \xc2\xa9 1999-2003 Lars Rydlinge",
                           _("A Klotski clone"),
                           (const char **)authors, 
                           (const char **)documenters,
                           strcmp (translator_credits, "translator-credits") != 0 ? translator_credits : NULL,
                           pixbuf);
  
  if (pixbuf != NULL)
    gdk_pixbuf_unref (pixbuf);
  
  gtk_window_set_transient_for (GTK_WINDOW (about), GTK_WINDOW (window));
  g_signal_connect (G_OBJECT (about), "destroy",
                    G_CALLBACK (gtk_widget_destroyed), &about);
  gtk_widget_show_all (about);
}
