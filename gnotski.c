/* -*- mode:C; indent-tabs-mode: nil; tab-width: 8; c-basic-offset: 2; -*- */

/* 
 *   Gnome Klotski
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
#include <gconf/gconf-client.h>
#include <string.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#include <games-preimage.h>
#include <games-gridframe.h>
#include <games-stock.h>

#include "pieces.h"

#define APPNAME "gnotski"
#define APPNAME_LONG "Klotski"

#define MINWIDTH 250
#define MINHEIGHT 250
#define THEME_TILE_CENTER 14
#define THEME_TILE_SIZE 34
#define THEME_TILE_SEGMENTS 27
#define THEME_OVERLAY_SIZE 8
#define SPACE_PADDING 5
#define SPACE_OFFSET 4

GConfClient *conf_client;

GtkWidget *window;
GtkWidget *statusbar;
GtkWidget *space;
GtkWidget *gameframe;
GtkWidget *messagewidget;
GtkWidget *moveswidget;

GdkGC *space_gc = NULL;

GdkPixmap *buffer = NULL;
GdkPixbuf *tiles_pixbuf = NULL;
GamesPreimage *tiles_preimage;

GtkActionGroup *action_group;

gboolean clear_buffer = TRUE;
gboolean clear_game = TRUE;

gchar *map = NULL;
gchar *tmpmap = NULL;
gchar *move_map = NULL;
gchar *orig_map = NULL;
gchar *lastmove_map = NULL;
gchar *undomove_map = NULL;

gchar current_level_scorefile[4];

gint space_width = 0;
gint space_height = 0;
gint tile_size = 0;
gint prior_tile_size = 0;
gint height = -1;
gint width = -1;
gint moves = 0;
gint session_xpos = 0;
gint session_ypos = 0;
gint current_level = -1;

guint redraw_all_idle_id = 0;
guint configure_idle_id = 0;

void create_space (void);
GtkWidget * create_menubar (void);
void create_statusbar (void);

void load_image (void);
void gui_draw_space (void);
void gui_draw_pixmap (char *, gint, gint);
gint get_piece_nr (char *, gint, gint);
gint get_piece_id (char *, gint, gint);
void set_piece_id (char *, gint, gint, gint);
gint move_piece (gint, gint, gint, gint, gint);
void copymap (char *, char *);
gint mapcmp (char *, char *);
gint save_state (GnomeClient *, gint, GnomeRestartStyle, gint,
                        GnomeInteractStyle, gint fast, gpointer);
void new_move (void);
void game_score (void);
gint game_over (void);

gboolean window_resize_cb (GtkWidget *, GdkEventConfigure *, gpointer);

void new_game (gint requested_level);

void next_level_cb (GtkAction *);
void prev_level_cb (GtkAction *);
void level_cb (GtkAction *, GtkRadioAction *);
void quit_game_cb (GtkAction *);
void restart_level_cb (GtkAction *);
void help_cb (GtkAction *);
void about_cb (GtkAction *);
void score_cb (GtkAction *);

/* Puzzle Info */

typedef struct _levelinfo {
  gchar *name;
  gint group;
  gint width;
  gint height;
  gint minimum_moves;
  gchar *data;
} levelinfo;

/* The "puzzle name" remarks provide context for translation. */
const levelinfo level[]= {
     /* puzzle name */ 
  { N_("Only 18 Steps"), 0,
    6, 9, 18,
    "######" \
    "#a**b#" \
    "#m**n#" \
    "#cdef#" \
    "#ghij#" \
    "#k  l#" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name */
  { N_("Daisy"), 0,
    6, 9, 28,
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdef#" \
    "#zghi#" \
    "#j  k#" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name */
  { N_("Violet"), 0,
    6, 9, 27,
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdef#" \
    "#cghi#" \
    "#j  k#" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name */
  { N_("Poppy"), 0,
    6, 9, 40,
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdde#" \
    "#fghi#" \
    "#j  k#" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name */ 
  { N_("Pansy"), 0,
    6, 9, 28,
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdef#" \
    "#cghf#" \
    "#i  j#" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name */
  { N_("Snowdrop"), 0,
    6, 9, 46,
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdde#" \
    "#cfgh#" \
    "#i  j#" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name - sometimes called "Le'Ane Rouge" */
  { N_("Red Donkey"), 0,
    6, 9, 81,
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdde#" \
    "#cfge#" \
    "#h  i#" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name */
  { N_("Trail"), 0,
    6, 9, 102,
    "######" \
    "#a**c#" \
    "#a**c#" \
    "#eddg#" \
    "#hffj#" \
    "# ii #" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name */
  { N_("Ambush"), 0,
    6, 9, 120,
    "######" \
    "#a**c#" \
    "#d**e#" \
    "#dffe#" \
    "#ghhi#" \
    "# jj #" \
    "##--##" \
    "    .." \
    "    .." },

     /* puzzle name */
  { N_("Agatka"), 1,
    7, 7, 30,
    "..     " \
    ".      " \
    "#####--" \
    "#**aab-" \
    "#*ccde#" \
    "#fgh  #" \
    "#######" },

     /* puzzle name */
  { N_("Success"), 1,
    9, 6, 25,
    "#######  " \
    "#**bbc#  " \
    "#defgh#  " \
    "#ijkgh-  " \
    "#llk  #  " \
    "#######.." },

     /* puzzle name */
  { N_("Bone"), 1,
    6, 9, 14,
    "######" \
    "#abc*#" \
    "# dd*#" \
    "# ee*#" \
    "# fgh#" \
    "##-###" \
    "     ." \
    "     ." \
    "     ." },

     /* puzzle name */
  { N_("Fortune"), 1,
    7, 10, 25,
    "     .." \
    "     . " \
    "####-. " \
    "#ab  - " \
    "#ccd # " \
    "#ccd # " \
    "#**ee# " \
    "#*fgh# " \
    "#*iih# " \
    "###### " },

     /* puzzle name */
  { N_("Fool"), 1,
    10, 6, 29,
    "  ########" \
    "  -aabc  #" \
    "  #aabdef#" \
    "  #ijggef#" \
    "  #klhh**#" \
    "..########" },

     /* puzzle name */
  { N_("Solomon"), 1,
    7, 9, 29, 
    " .     " \
    "..     " \
    "#--####" \
    "#  aab#" \
    "# cdfb#" \
    "#hcefg#" \
    "#hijk*#" \
    "#hll**#" \
    "#######" },

     /* puzzle name */
  { N_("Cleopatra"), 1,
    6, 8, 32, 
    "######" \
    "#abcd#" \
    "#**ee#" \
    "#f*g #" \
    "#fh i-" \
    "####--" \
    "    .." \
    "     ." },

     /* puzzle name */
  { N_("Shark"), 1,
    11, 8, 0, /* SOLVEME */
    "########   " \
    "#nrr s #   " \
    "#n*op q#   " \
    "#***jml#   " \
    "#hhijkl#   " \
    "#ffcddg-   " \
    "#abcdde- . " \
    "########..." },

     /* puzzle name */
  { N_("Rome"), 1,
    8, 8, 38, 
    "########" \
    "#abcc**#" \
    "#ddeef*#" \
    "#ddghfi#" \
    "#   jki#" \
    "#--#####" \
    " ..     " \
    "  .     " },

     /* puzzle name */
  { N_("Pennant Puzzle"), 1,
    6, 9, 59,
    "######" \
    "#**aa#" \
    "#**bb#" \
    "#de  #" \
    "#fghh#" \
    "#fgii#" \
    "#--###" \
    "    .." \
    "    .." },

     /* puzzle name */
  { N_("Ithaca"), 2,
    19, 19, 0, /* SOLVEME */
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
    "ttttttuvvvvvvvwwwwx" },

     /* puzzle name */
  { N_("Pelopones"), 2,
    9, 8, 0, /* SOLVEME */
    "#########" \
    "#abbb***#" \
    "#abbb*c*#" \
    "#adeefgg#" \
    "#  eefhh#" \
    "#... ihh#" \
    "#. . ihh#" \
    "#########" },

     /* puzzle name */
  { N_("Transeuropa"), 2,
    15, 8, 0, /* SOLVEME */
    "    ###########" \
    "    -AAAAABBCC#" \
    "    -   DEFGHI#" \
    "    #   DEFGJI#" \
    "    #   KEFGLI#" \
    "    #   KEFG*I#" \
    "  . #   MM****#" \
    "....###########" },

     /* puzzle name */
  { N_("Lodzianka"), 2,
    9, 7, 0, /* SOLVEME */
    "#########" \
    "#**abbcc#" \
    "#**abbdd#" \
    "#eefgh  #" \
    "#iiijk..#" \
    "#iiijk..#" \
    "#########" },

     /* puzzle name */
  { N_("Polonaise"), 2,
    7, 7, 0, /* SOLVEME */
    "#######" \
    "#aab**#" \
    "#aabc*#" \
    "#defgg#" \
    "#..fhh#" \
    "# .ihh#" \
    "#######" },

     /* puzzle name */
  { N_("Baltic Sea"), 2,
    6, 8, 42,
    "######" \
    "#.abc#" \
    "#.dec#" \
    "#fggc#" \
    "#fhhi#" \
    "#fjk*#" \
    "#flk*#" \
    "######" },

     /* puzzle name */
  { N_("American Pie"), 2,
    10, 12, 0, /* SOLVEME */
    "##########" \
    "#a*bcdefg#" \
    "#**bhhhhg#" \
    "#*iijjkkg#" \
    "#liimnoop#" \
    "#qiirrr  #" \
    "#qstuvv  #" \
    "#qwwxvv  #" \
    "######--##" \
    "         ." \
    "        .." \
    "        . " },

     /* puzzle name */
  { N_("Traffic Jam"), 2,
    10, 7, 132,
    "########  " \
    "#** ffi#  " \
    "#** fgh#  " \
    "#aacehh#  " \
    "#bbdjlm-  " \
    "#bddklm-.." \
    "########.." },

     /* puzzle name */
  { N_("Sunshine"), 2,
    17, 22, 345,
    "       ...       " \
    "      .. ..      " \
    "      .   .      " \
    "      .. ..      " \
    "       ...       " \
    "######-----######" \
    "#hh0iilltmmpp;qq#" \
    "#hh,iill mmpp:qq#" \
    "#2y{45v s w89x/z#" \
    "#jj6kkaa nnoo<rr#" \
    "#jj7kkaaunnoo>rr#" \
    "#33333TTJWW11111#" \
    "#33333TTJWW11111#" \
    "#33333GG HH11111#" \
    "#33333YYIgg11111#" \
    "#33333YYIgg11111#" \
    "#ddFeeA***BffOZZ#" \
    "#ddFee** **ffOZZ#" \
    "#MMKQQ*   *PPS^^#" \
    "#VVLXX** **bbRcc#" \
    "#VVLXXD***EbbRcc#" \
    "#################" },

     /* puzzle name */
  { N_("Block 10"), 3,
    6, 7, 30,
    "##..##" \
    "#a..c#" \
    "#abcc#" \
    "#ddfg#" \
    "#d**g#" \
    "#e**h#" \
    "######" },

     /* puzzle name */
  { N_("Block 10 Pro"), 3,
    6, 7, 81,
    "##..##" \
    "#a..b#" \
    "#ccdd#" \
    "#ecdf#" \
    "#e**f#" \
    "#g**h#" \
    "######" },

     /* puzzle name */
  { N_("Climb 12"), 3,
    7, 7, 59,
    "###.###" \
    "#a...b#" \
    "#accdb#" \
    "#ecddf#" \
    "#gg*hh#" \
    "#i***j#" \
    "#######" },

     /* puzzle name */
  { N_("Climb 12 Pro"), 3,
    7, 7, 92,
    "###.###" \
    "#a...b#" \
    "#acddb#" \
    "#effgh#" \
    "#ee*hh#" \
    "#i***j#" \
    "#######" },

     /* puzzle name */
  { N_("Climb 15 Winter"), 3,
    7, 9, 101,
    "###.###" \
    "#a...b#" \
    "#cdefg#" \
    "#ccegg#" \
    "#hhijj#" \
    "#hhikk#" \
    "#ll*mm#" \
    "#l***m#" \
    "#######" },

     /* puzzle name */
  { N_("Climb 15 Spring"), 3,
    7, 9, 104,
    "###.###" \
    "#a...b#" \
    "#fedcc#" \
    "#feddc#" \
    "#hhigg#" \
    "#hiigg#" \
    "#ll*mm#" \
    "#j***k#" \
    "#######" },

     /* puzzle name */
  { N_("Climb 15 Summer"), 3,
    7, 9, 132,
    "###.###" \
    "#a...b#" \
    "#cceff#" \
    "#ddeff#" \
    "#gghii#" \
    "#kghij#" \
    "#kk*jj#" \
    "#l***m#" \
    "#######" },

     /* puzzle name */
  { N_("Climb 15 Fall"), 3,
    7, 9, 148,
    "###.###" \
    "#a...b#" \
    "#cceff#" \
    "#ddegg#" \
    "#dijjg#" \
    "#hijjk#" \
    "#hh*kk#" \
    "#l***l#" \
    "#######" },

     /* puzzle name */
  { N_("Climb 24 Pro"), 3,
    9, 11, 227,
    "####.####" \
    "#aa...bb#" \
    "#ccdddee#" \
    "#ccfggee#" \
    "#hhffgnn#" \
    "#ihklmno#" \
    "#ijkzmpo#" \
    "#jjqqqpp#" \
    "#rrs*tuu#" \
    "#rr***uu#" \
    "#########" },
};

const gint max_level = G_N_ELEMENTS(level) - 1;
GtkToggleAction *level_action[G_N_ELEMENTS(level)];

/* Menu Info */

const char *pack_uipath[] = { 
                 "/ui/MainMenu/GameMenu/HuaRongTrail", 
                 "/ui/MainMenu/GameMenu/ChallengePack", 
                 "/ui/MainMenu/GameMenu/SkillPack",
                 "/ui/MainMenu/GameMenu/MinoruClimb"
};

const GtkActionEntry entries[] = {
  { "GameMenu", NULL, N_("_Game") },
  { "HelpMenu", NULL, N_("_Help") },
                           /* set of puzzles */
  { "HuaRongTrail", NULL, N_("HuaRong Trail") },
                            /* set of puzzles */
  { "ChallengePack", NULL, N_("Challenge Pack") },
                        /* set of puzzles */
  { "SkillPack", NULL, N_("Skill Pack") },
                          /* set of puzzles */
  { "MinoruClimb", NULL, N_("Minoru Climb") },
  { "RestartPuzzle", GTK_STOCK_REFRESH, N_("_Restart Puzzle"), "<control>R", NULL, G_CALLBACK (restart_level_cb) },
  { "NextPuzzle", GTK_STOCK_GO_FORWARD, N_("Next Puzzle"), "Page_Down", NULL, G_CALLBACK (next_level_cb) },
  { "PrevPuzzle", GTK_STOCK_GO_BACK, N_("Previous Puzzle"), "Page_Up", NULL, G_CALLBACK (prev_level_cb) },
  { "Quit", GTK_STOCK_QUIT,  NULL, NULL, NULL, G_CALLBACK (quit_game_cb) },
  { "Contents", GAMES_STOCK_CONTENTS, NULL, NULL, NULL, G_CALLBACK (help_cb) },
  { "About", GTK_STOCK_ABOUT, NULL, NULL, NULL, G_CALLBACK (about_cb) },
  { "Scores", GAMES_STOCK_SCORES, NULL, NULL, NULL, G_CALLBACK (score_cb) }
};

const char ui_description[] =
"<ui>"
"  <menubar name='MainMenu'>"
"    <menu action='GameMenu'>"
"      <menuitem action='RestartPuzzle'/>"
"      <menuitem action='NextPuzzle'/>"
"      <menuitem action='PrevPuzzle'/>"
"      <separator/>"
"      <menu action='HuaRongTrail'/>"
"      <menu action='ChallengePack'/>"
"      <menu action='SkillPack'/>"
"      <menu action='MinoruClimb'/>"
"      <separator/>"
"      <menuitem action='Scores'/>"
"      <separator/>"
"      <menuitem action='Quit'/>"
"    </menu>"
"    <menu action='HelpMenu'>"
"      <menuitem action='Contents'/>"
"      <menuitem action='About'/>"
"    </menu>"
"  </menubar>"
"</ui>";

/* Session Options */

static const GOptionEntry options[] = {
  { "x", 'x', 0, G_OPTION_ARG_INT, &session_xpos, N_("X location of window"), 
   N_("X")},
  { "y", 'y', 0, G_OPTION_ARG_INT, &session_ypos, N_("Y location of window"), 
   N_("Y")},
  { NULL }
};

/* ------------------------------------------------------- */

int
main (int argc, char **argv)
{
  GnomeClient *client;
  GnomeProgram *program;
  GtkWidget *vbox;
  GtkWidget *menubar;
  gint win_width, win_height, startup_level;
  GOptionContext *context;

  gnome_score_init (APPNAME);
  bindtextdomain (GETTEXT_PACKAGE, GNOMELOCALEDIR);
  bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
  textdomain (GETTEXT_PACKAGE);
  
  context = g_option_context_new ("");
  g_option_context_add_main_entries (context, options, GETTEXT_PACKAGE);
  program = gnome_program_init (APPNAME, VERSION,
                                LIBGNOMEUI_MODULE,
                                argc, argv,
                                GNOME_PARAM_GOPTION_CONTEXT, context,
                                GNOME_PARAM_APP_DATADIR, DATADIR, NULL);
  games_stock_init ();
  gtk_window_set_default_icon_name ("gnome-klotski.png");
  client = gnome_master_client ();
  g_object_ref (G_OBJECT (client));
  gtk_object_sink (GTK_OBJECT (client));
  g_signal_connect (G_OBJECT (client), "save_yourself", 
                    G_CALLBACK (save_state), argv[0]);
  g_signal_connect (G_OBJECT (client), "die",
                    G_CALLBACK (quit_game_cb), argv[0]);

  conf_client = gconf_client_get_default ();

  window = gnome_app_new (APPNAME, N_(APPNAME_LONG));

  win_width = gconf_client_get_int (conf_client, "/apps/gnotski/width", NULL);
  win_height = gconf_client_get_int (conf_client, "/apps/gnotski/height", NULL);
  startup_level = gconf_client_get_int (conf_client, "/apps/gnotski/level", NULL);

  gtk_window_set_default_size (GTK_WINDOW (window), win_width, win_height);
  
  g_signal_connect (G_OBJECT (window), "delete_event",
                    G_CALLBACK(quit_game_cb), NULL);
  g_signal_connect (G_OBJECT (window), "configure_event",
                    G_CALLBACK(window_resize_cb), NULL);
  
  vbox = gtk_vbox_new (FALSE, 0);
  gnome_app_set_contents (GNOME_APP (window), vbox);

  load_image ();
  create_space ();
  menubar = create_menubar ();
  create_statusbar ();

  gtk_box_pack_start (GTK_BOX (vbox), menubar, FALSE, FALSE, 0);
  gtk_box_pack_start (GTK_BOX (vbox), gameframe, TRUE, TRUE, 0);
  gtk_box_pack_start (GTK_BOX (vbox), gtk_hseparator_new (), FALSE, FALSE, 0);
  gtk_box_pack_end (GTK_BOX (vbox), statusbar, FALSE, FALSE, GNOME_PAD);
 
  if (session_xpos >= 0 && session_ypos >= 0)
    gtk_window_move (GTK_WINDOW (window), session_xpos, session_ypos);
    
  gtk_widget_show_all (window);

  new_game (startup_level);
  
  gtk_main ();

  gnome_accelerators_sync();

  g_object_unref (program);
  
  return 0;
}

static gboolean
expose_space (GtkWidget *widget, GdkEventExpose *event)
{
  if (clear_game)
    return FALSE;

  gdk_draw_drawable (widget->window, 
                     widget->style->fg_gc[GTK_WIDGET_STATE(widget)], 
                     buffer, event->area.x, event->area.y, 
                     event->area.x, event->area.y, 
                     event->area.width, event->area.height);
  return FALSE; 
}

static gboolean
redraw_all (void)
{
  gint x, y;

  if (clear_buffer)
    gui_draw_space();

  for (y = 0; y < height; y++)
    for (x = 0; x < width; x++)
      gui_draw_pixmap (map, x, y);

  return FALSE;
}

static gboolean
movable (gint id)
{
  if (id == '#' || id == '.' || id == ' ' || id == '-')
     return FALSE;
  return TRUE;
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
    piece_x = (gint) event->x / tile_size;
    piece_y = (gint) event->y / tile_size;
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
	    gtk_label_set_text (GTK_LABEL (messagewidget), _("Level completed."));
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
    new_piece_x = (gint) event->x / tile_size;
    new_piece_y = (gint) event->y / tile_size;
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
gui_draw_space ()
{
  static GdkGC *bordergc = NULL;
  static GdkGC *backgc = NULL;
  GdkColor *bg_color;
  GtkStyle *style;

  if (!backgc)
    backgc = gdk_gc_new (space->window);
  if (!bordergc)
    bordergc = gdk_gc_new (space->window);

  style = gtk_widget_get_style (space);

  bg_color = gdk_color_copy (&style->bg[GTK_STATE_NORMAL]);
  gdk_gc_set_foreground (backgc, bg_color);
  gdk_gc_set_fill (backgc, GDK_SOLID);
  gdk_color_free (bg_color);

  bg_color = gdk_color_copy (&style->fg[GTK_STATE_NORMAL]);
  gdk_gc_set_foreground (bordergc, bg_color);
  gdk_gc_set_fill (bordergc, GDK_SOLID);
  gdk_color_free (bg_color);
 
  if (buffer)
    g_object_unref (buffer);
  
  buffer = gdk_pixmap_new (space->window,
                           width * tile_size + SPACE_PADDING,
                           height * tile_size + SPACE_PADDING, -1);

  gdk_draw_rectangle (buffer, bordergc, FALSE, 0, 0,
                      width * tile_size + SPACE_PADDING -1,
                      height * tile_size + SPACE_PADDING -1);
  gdk_draw_rectangle (buffer, backgc, TRUE, 1, 1,
                      width * tile_size + SPACE_PADDING - 2,
                      height * tile_size + SPACE_PADDING - 2);

  clear_buffer = clear_game = FALSE;

  space_gc = backgc;  

  gtk_widget_queue_draw (space);
}

void
gui_draw_pixmap (char *target, gint x, gint y)
{
  gint value;
  gint overlay_size;
  gint overlay_offset;
  
  gdk_draw_rectangle (buffer, space_gc, TRUE,
                      x * tile_size + SPACE_OFFSET, 
                      y * tile_size + SPACE_OFFSET,
                      tile_size, tile_size);

  if (get_piece_id (target,x,y) != ' ') {
    gdk_draw_pixbuf (buffer, NULL, tiles_pixbuf,
                     get_piece_nr (target,x,y) * tile_size, tile_size/2, 
                     x * tile_size + SPACE_OFFSET, 
                     y * tile_size + SPACE_OFFSET,
                     tile_size, tile_size,
                     GDK_RGB_DITHER_NORMAL, 0, 0);
  }
  
  if (get_piece_id (target, x, y) == '*') {
    if (get_piece_id (orig_map, x, y) == '.')
      value = 20;
    else
      value = 22;
   
    overlay_size = THEME_OVERLAY_SIZE * tile_size / THEME_TILE_SIZE;
    overlay_offset = THEME_TILE_CENTER * tile_size / THEME_TILE_SIZE - overlay_size / 2;
    gdk_draw_pixbuf (buffer, NULL, tiles_pixbuf,
                     value * tile_size + overlay_offset, 
                     overlay_offset + tile_size/2,
                     x * tile_size + overlay_offset + SPACE_OFFSET, 
                     y * tile_size + overlay_offset + SPACE_OFFSET, 
                     overlay_size, overlay_size,
                     GDK_RGB_DITHER_NORMAL, 0, 0);
  }

  gtk_widget_queue_draw_area (space, 
                              x * tile_size + SPACE_OFFSET, 
                              y * tile_size + SPACE_OFFSET,
                              tile_size, tile_size);
}


static void
show_score_dialog (gint pos)
{
  GtkWidget *dialog;

  dialog = gnome_scores_display (_(APPNAME_LONG), APPNAME, 
                                 current_level_scorefile, pos);
  if (dialog != NULL) {
    gtk_window_set_transient_for (GTK_WINDOW (dialog), GTK_WINDOW (window));
    gtk_window_set_modal (GTK_WINDOW (dialog), TRUE);
  }
}

void
score_cb (GtkAction *action)
{
  show_score_dialog (0);
}

static void
update_score_state (void)
{
  GtkAction *score_action;
  gchar **names = NULL;
  gfloat *scores = NULL;
  time_t *scoretimes = NULL;
  gint top;
  
  score_action = gtk_action_group_get_action (action_group, "Scores");
  top = gnome_score_get_notable (APPNAME, current_level_scorefile,
                                 &names, &scores, &scoretimes);
  if (top > 0) {
    gtk_action_set_sensitive (score_action, TRUE);
    g_strfreev (names);
    g_free (scores);
    g_free (scoretimes);
  } else {
    gtk_action_set_sensitive (score_action, FALSE);
  }
}

void
game_score ()
{
  gint pos;
  pos = gnome_score_log (moves, current_level_scorefile, FALSE);
  update_score_state ();
  show_score_dialog (pos);
}

static gboolean
configure_pixmaps_idle (void)
{
  if (tile_size != prior_tile_size) {

    if (tiles_pixbuf != NULL) 
      g_object_unref (tiles_pixbuf);
    tiles_pixbuf = NULL;
    
    if (tiles_preimage) {
      tiles_pixbuf = games_preimage_render (tiles_preimage,
                                            tile_size * THEME_TILE_SEGMENTS,
                                            tile_size * 2, NULL);
    }

    if (tiles_pixbuf == NULL) {
      GtkWidget *dialog;
      dialog = gtk_message_dialog_new (GTK_WINDOW (window),
                                       GTK_DIALOG_MODAL,
                                       GTK_MESSAGE_ERROR,
                                       GTK_BUTTONS_OK,
                                       _("The theme for this game failed to render.\n\nPlease check that Klotski is installed correctly."));
      gtk_dialog_run (GTK_DIALOG (dialog));
      exit (1);
    }

    prior_tile_size = tile_size;
  }

  if (redraw_all_idle_id)
    g_source_remove (redraw_all_idle_id);

  redraw_all_idle_id = g_idle_add_full (G_PRIORITY_DEFAULT_IDLE + 1, 
                                        (GSourceFunc) redraw_all, 
                                        NULL, NULL);

  configure_idle_id = 0;
  return FALSE;
}

static void
configure_pixmaps (void)
{
  tile_size = MIN (((space_width - SPACE_PADDING) / width),
                   ((space_height - SPACE_PADDING) / height));
  
  /* SVG theme renders best when tile size is multiple of 2 */
  if (tile_size < 1) return;

  if (tile_size % 2) tile_size--;

  if (clear_buffer || clear_game || (tile_size != prior_tile_size)) {
    if (configure_idle_id)
      g_source_remove (configure_idle_id);

    configure_idle_id = g_idle_add ((GSourceFunc) configure_pixmaps_idle, NULL);

    clear_buffer = TRUE;
  }
  
  return;
}

static gboolean
configure_space (GtkWidget *widget, GdkEventConfigure *event)
{
  space_width = event -> width;
  space_height = event -> height;
  configure_pixmaps ();

  return TRUE;
}

void
create_space (void)
{
  gameframe = games_grid_frame_new (9,7);
  games_grid_frame_set_padding (GAMES_GRID_FRAME(gameframe),
                                SPACE_PADDING, SPACE_PADDING);
  gtk_widget_set_size_request (GTK_WIDGET(gameframe),
                               MINWIDTH, MINHEIGHT);
  
  space = gtk_drawing_area_new ();

  gtk_container_add (GTK_CONTAINER(gameframe),space);
  gtk_widget_set_events (space, GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK
                         | GDK_POINTER_MOTION_MASK | GDK_BUTTON_RELEASE_MASK);
  g_signal_connect (G_OBJECT(space), "expose_event", 
                    G_CALLBACK (expose_space), NULL);
  g_signal_connect (G_OBJECT(space), "configure_event", 
                    G_CALLBACK (configure_space), NULL);
  g_signal_connect (G_OBJECT(space), "button_press_event", 
                    G_CALLBACK (button_press_space), NULL);
  g_signal_connect (G_OBJECT(space), "button_release_event",
                    G_CALLBACK (button_release_space), NULL);
  g_signal_connect (G_OBJECT(space), "motion_notify_event",
                    G_CALLBACK (button_motion_space), NULL);
}

/* Add puzzles to the game menu. */
static
void add_puzzle_menu (GtkUIManager *ui_manager)
{
  gint i;
  GSList *group = NULL;
  GtkRadioAction *top_action;

  g_return_if_fail (GTK_IS_ACTION_GROUP (action_group));

  for (i = max_level; i >= 0 ; i--)
    {
      GtkRadioAction *action;
      const gchar *label;

      label = gtk_action_group_translate_string (action_group, level[i].name);

      action = top_action = gtk_radio_action_new (level[i].name, label,
                                                  NULL, NULL, i);

      gtk_radio_action_set_group (action, group);
      group = gtk_radio_action_get_group (action);

      gtk_action_group_add_action(action_group, GTK_ACTION (action));

      gtk_ui_manager_add_ui (ui_manager, 
                             gtk_ui_manager_new_merge_id (ui_manager),
                             pack_uipath[level[i].group], 
                             level[i].name, level[i].name, 
                             GTK_UI_MANAGER_MENUITEM, TRUE);

      level_action[i] = GTK_TOGGLE_ACTION (action);
    }

  g_signal_connect_data (top_action, "changed",
			 G_CALLBACK(level_cb), window, 
			 NULL, 0);
}

GtkWidget *
create_menubar (void)
{
  GtkUIManager *ui_manager;
  GtkAccelGroup *accel_group;

  action_group = gtk_action_group_new ("MenuActions");
  gtk_action_group_set_translation_domain (action_group, GETTEXT_PACKAGE);
  gtk_action_group_add_actions (action_group, entries,
                                G_N_ELEMENTS (entries), window);

  ui_manager = gtk_ui_manager_new();
  gtk_ui_manager_insert_action_group (ui_manager, action_group, 0);
  gtk_ui_manager_add_ui_from_string (ui_manager, ui_description, -1, NULL);
  add_puzzle_menu (ui_manager);

  accel_group = gtk_ui_manager_get_accel_group (ui_manager);
  gtk_window_add_accel_group (GTK_WINDOW (window), accel_group);
  
  return gtk_ui_manager_get_widget (ui_manager, "/MainMenu");
}

void
create_statusbar (void)
{
  statusbar = gtk_hbox_new (TRUE, 0);

  messagewidget = gtk_label_new ("");
  gtk_box_pack_start (GTK_BOX (statusbar), messagewidget, FALSE, FALSE, 0);


  moveswidget = gtk_label_new ("");
  gtk_box_pack_end (GTK_BOX (statusbar), moveswidget, FALSE, FALSE, 0);
}

void
load_image (void)
{
  char *fname;

  fname = gnome_program_locate_file (NULL, GNOME_FILE_DOMAIN_APP_PIXMAP, 
                                     "gnotski.svg", FALSE, NULL);
  if (g_file_test (fname, G_FILE_TEST_EXISTS)) {
    tiles_preimage = games_preimage_new_from_file (fname, NULL);
  } else {
    GtkWidget *dialog;

    dialog = gtk_message_dialog_new (NULL,
                                     GTK_DIALOG_MODAL,
                                     GTK_MESSAGE_ERROR,
                                     GTK_BUTTONS_OK,
                                     _("Could not find the image:\n%s\n\nPlease check that Klotski is installed correctly."),
                                     fname);
    gtk_dialog_run (GTK_DIALOG (dialog));
    exit (1);
  }
  g_free (fname);
}

static void
set_move (gint x)
{
  moves = x - 1;
  new_move ();
}

void
new_move (void)
{
  static gint last_piece_id = -2;
  gchar *str = NULL;

  if (moves < 1)
	last_piece_id = -2;

  if (last_piece_id != piece_id) {
    copymap (undomove_map, lastmove_map);
    if (moves < 999) 
      moves++;
  }

  if ((moves > 0) && !mapcmp(undomove_map,map)) {    
    moves--;
    last_piece_id = -2;
  } else {
    last_piece_id = piece_id;
  }

  copymap (lastmove_map, map);

  str = g_strdup_printf (_("Moves: %d"), moves);
  gtk_label_set_text (GTK_LABEL (moveswidget), str);
  g_free (str);
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

static gint
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

static gint
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
prepare_map (current_level)
{
  gint x, y = 0;
  gchar *leveldata;

  leveldata = level[current_level].data; 
  width = level[current_level].width;
  height = level[current_level].height;
  gtk_label_set_text (GTK_LABEL (messagewidget), _(level[current_level].name));

  if (map) {
    free (map);
    free (tmpmap);
    free (move_map);
    free (orig_map);
    free (lastmove_map);
    free (undomove_map);
  }

  piece_id = -1;
  button_down = piece_x = piece_y = 0;

  map = calloc (1, (width + 2) * (height + 2));
  tmpmap = calloc (1, (width + 2) * (height + 2));
  orig_map = calloc (1, (width + 2) * (height + 2));
  move_map = calloc (1, (width + 2) * (height + 2));
  lastmove_map = calloc (1, (width + 2) * (height + 2));
  undomove_map = calloc (1, (width + 2) * (height + 2));
  if (leveldata)
    for (y = 0; y < height; y++)
      for (x = 0; x < width; x++)
        set_piece_id (map, x, y, *leveldata++);
  copymap (orig_map, map);
  copymap (lastmove_map, map);
}

static void
update_menu_state (void)
{
  GtkAction *action;
  gboolean action_is_sensitive;

  /* Puzzle Radio Action */
  gtk_toggle_action_set_active (level_action[current_level], TRUE);

  /* Next Puzzle Sensitivity */
  action_is_sensitive = current_level < max_level;
  action = gtk_action_group_get_action (action_group, "NextPuzzle");
  gtk_action_set_sensitive (action, action_is_sensitive);

  /* Previous Puzzle Sensitivity */
  action_is_sensitive = current_level > 0;
  action = gtk_action_group_get_action (action_group, "PrevPuzzle");
  gtk_action_set_sensitive (action, action_is_sensitive);
}

void
new_game (gint requested_level)
{
  clear_game = TRUE;

  set_move (0);
  current_level = CLAMP (requested_level, 0, max_level);

  g_snprintf (current_level_scorefile, sizeof(current_level_scorefile), 
              "%d", current_level+1);
  gconf_client_set_int (conf_client, "/apps/gnotski/level",
                        current_level, NULL);

  prepare_map (current_level);
  games_grid_frame_set (GAMES_GRID_FRAME(gameframe), width, height);
  configure_pixmaps();
  update_menu_state ();
  update_score_state ();
}

void
quit_game_cb (GtkAction *action)
{
  gtk_main_quit ();
}

gboolean
window_resize_cb (GtkWidget *w, GdkEventConfigure *e, gpointer data)
{
  gconf_client_set_int (conf_client, "/apps/gnotski/width",
                        e->width, NULL);
  gconf_client_set_int (conf_client, "/apps/gnotski/height",
                        e->height, NULL);	
  return FALSE;
}

gint
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
level_cb (GtkAction *action, GtkRadioAction *current)
{
  gint requested_level = gtk_radio_action_get_current_value (current);
  if (requested_level != current_level)
    new_game (requested_level);
}

void
restart_level_cb (GtkAction *action)
{
  new_game (current_level);
}

void
next_level_cb (GtkAction *action)
{ 
  new_game (current_level + 1);
}

void
prev_level_cb (GtkAction *action)
{
  new_game (current_level - 1);
}

void
help_cb (GtkAction *action)
{
  gnome_help_display ("gnotski.xml", NULL, NULL);
}

void
about_cb (GtkAction *action)
{
  const gchar *authors[] = { "Lars Rydlinge", NULL };
  const gchar *documenters[] = { "Andrew Sobala", NULL };

  gtk_show_about_dialog (GTK_WINDOW (window),
                         "name", _(APPNAME_LONG),
                         "version", VERSION,
                         "comments", _("Sliding Block Puzzles"),
                         "copyright", "Copyright \xc2\xa9 1999-2004 Lars Rydlinge",
                         "authors", authors,
                         "documenters", documenters,
                         "translator_credits", _("translator-credits"),
                         "logo-icon-name", "gnome-klotski",
                         NULL);
}
