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
#include <gconf/gconf-client.h>
#include <string.h>
#include <libgnomeui/gnome-window-icon.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#include "games-preimage.h"
#include "games-gridframe.h"

#include "pieces.h"

#define APPNAME "gnotski"
#define APPNAME_LONG "GNOME Klotski"

#define RELEASE 4
#define PRESS 3
#define MOVING 2
#define UNUSED 1
#define USED 0

#define MINWIDTH 250
#define MINHEIGHT 250

#define THEME_TILE_CENTER 14
#define THEME_TILE_SIZE 34
#define THEME_OVERLAY_SIZE 8

GConfClient *conf_client;

GtkWidget *window;
GtkWidget *statusbar;
GtkWidget *space;
GtkWidget *move_value;
GtkWidget *outerframe;
GtkWidget *gameframe;

GdkPixmap *buffer = NULL;
GdkPixbuf *tiles_pixbuf = NULL;
GamesPreimage *tiles_preimage;

gint space_width = 0;
gint space_height = 0;

gboolean clear_buffer = FALSE;

char *map = NULL;
char *tmpmap = NULL;
char *move_map = NULL;
char *orig_map = NULL;

gint tile_size = 0,
  prior_tile_size = 0;
gint height = -1, 
  width = -1;
gint moves = 0;
gint session_xpos = 0;
gint session_ypos = 0;

guint draw_idle_id = 0;

char current_level[16];

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
void set_move (gint);
void new_move (void);
gint game_over (void);
void game_score (void);

static gboolean window_resize_cb (GtkWidget *, GdkEventConfigure *, gpointer);

/* ------------------------- MENU ------------------------ */
void new_game_cb (GtkWidget *, gpointer);
void quit_game_cb (GtkWidget *, gpointer);
void level_cb (GtkWidget *, gpointer);
void about_cb (GtkWidget *, gpointer);
void score_cb (GtkWidget *, gpointer);

GnomeUIInfo level_1_menu[] = {
  { GNOME_APP_UI_ITEM, N_("1"), NULL, level_cb,
    "1#6#9#" \
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdef#" \
    "#ghij#" \
    "#k  l#" \
    "##--##" \
    "    .." \
    "    ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("2"), NULL, level_cb,
    "2#6#9#" \
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdef#" \
    "#cghi#" \
    "#j  k#" \
    "##--##" \
    "    .." \
    "    ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("3"), NULL, level_cb,
    "3#6#9#" \
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdde#" \
    "#fghi#" \
    "#j  k#" \
    "##--##" \
    "    .." \
    "    ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("4"), NULL, level_cb,
    "4#6#9#" \
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdef#" \
    "#cghf#" \
    "#i  j#" \
    "##--##" \
    "    .." \
    "    ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("5"), NULL, level_cb,
    "5#6#9#" \
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdde#" \
    "#cfgh#" \
    "#i  j#" \
    "##--##" \
    "    .." \
    "    ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("6"), NULL, level_cb,
    "6#6#9#" \
    "######" \
    "#a**b#" \
    "#a**b#" \
    "#cdde#" \
    "#cfge#" \
    "#h  i#" \
    "##--##" \
    "    .." \
    "    ..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("7"), NULL, level_cb,
    "7#7#7#" \
    "..     " \
    ".      " \
    "#####--" \
    "#**aab-" \
    "#*ccde#" \
    "#fgh  #" \
    "#######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  GNOMEUIINFO_END
};

GnomeUIInfo level_2_menu[] = {

  { GNOME_APP_UI_ITEM, N_("1"), NULL, level_cb,
    "11#9#6#" \
    "#######  " \
    "#**bbc#  " \
    "#defgh#  " \
    "#ijkgh-  " \
    "#llk  #  " \
    "#######..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },


  { GNOME_APP_UI_ITEM, N_("2"), NULL, level_cb,
    "12#6#9#" \
    "######" \
    "#abc*#" \
    "# dd*#" \
    "# ee*#" \
    "# fgh#" \
    "##-###" \
    "     ." \
    "     ." \
    "     .",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("3"), NULL, level_cb,
    "13#7#10#" \
    "     .." \
    "     . " \
    "####-. " \
    "#ab  - " \
    "#ccd # " \
    "#ccd # " \
    "#**ee# " \
    "#*fgh# " \
    "#*iih# " \
    "###### ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("4"), NULL, level_cb,
    "14#10#6#" \
    "  ########" \
    "  -aabc  #" \
    "  #aabdef#" \
    "  #ijggef#" \
    "  #klhh**#" \
    "..########",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("5"), NULL, level_cb,
    "15#7#9#" \
    " .     " \
    "..     " \
    "#--####" \
    "#  aab#" \
    "# cdfb#" \
    "-hcefg#" \
    "#hijk*#" \
    "#hll**#" \
    "#######",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("6"), NULL, level_cb,
    "16#6#8#" \
    "######" \
    "#abcd#" \
    "#**ee#" \
    "#f*g #" \
    "#fh i-" \
    "####--" \
    "    .." \
    "     .",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("7"), NULL, level_cb,
    "17#11#8#" \
    "########   " \
    "#nrr s #   " \
    "#n*op q#   " \
    "#***jml#   " \
    "#hhijkl#   " \
    "#ffcddg-   " \
    "#abcdde- . " \
    "########...",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("8"), NULL, level_cb,
    "18#8#8#" \
    "########" \
    "#abcc**#" \
    "#ddeef*#" \
    "#ddghfi#" \
    "-   jki#" \
    "#--#####" \
    "      .." \
    "       .",
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
    "22#9#10#" \
    "#########" \
    "#abbb***#" \
    "#abbb*c*#" \
    "#adeefgg#" \
    "#  eefhh#" \
    "#    ihh#" \
    "#    ihh#" \
    "#---#####" \
    "      ..." \
    "      . .",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("3"), NULL, level_cb,
    "23#15#8#" \
    "    -##-#######" \
    "    -AAAAABBCC#" \
    "    -   DEFGHI#" \
    "    #   DEFGJI#" \
    "    #   KEFGLI#" \
    "    #   KEFG*I#" \
    "  . #   MM****#" \
    "....###########",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("4"), NULL, level_cb,
    "24#11#7#" \
    "#########  " \
    "#**abbcc#  " \
    "#**abbdd#  " \
    "#eefgh  #  " \
    "#iiijk  -  " \
    "#iiijk  -.." \
    "#########..",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("5"), NULL, level_cb,
    "25#7#9#" \
    "#######" \
    "#aab**#" \
    "#aabc*#" \
    "-defgg#" \
    "#  fhh#" \
    "#  ihh#" \
    "#--####" \
    "     .." \
    "      .",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("6"), NULL, level_cb,
    "26#6#10#" \
    ".     " \
    ".     " \
    "#-####" \
    "# abc#" \
    "# dec#" \
    "#fggc#" \
    "#fhhi#" \
    "#fjk*#" \
    "#flk*#" \
    "######",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("7"), NULL, level_cb,
    "27#10#12#" \
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
    "        . ",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("8"), NULL, level_cb,
    "Sunshine#29#35#" \
    "           #######           " \
    "           # ... #           " \
    "           #.. ..#           " \
    "           #.   .#           " \
    "           #.. ..#           " \
    "           # ... #           " \
    "############-----############" \
    "#\x90\x90\x91\x92\x92\x80\x80\x80\x80\x80 \xb0\xb0\xb1\xb2\xb2 \x81\x81\x81\x81\x81\x98\x98\x99\x9a\x9a#" \
    "#\x90\x90\x91\x92\x92\x80\x80\x80\x80\x80 \xb0\xb0\xb1\xb2\xb2 \x81\x81\x81\x81\x81\x98\x98\x99\x9a\x9a#" \
    "#\x93\x93 \x94\x94\x80\x80\x80\x80\x80 \xb3\xb3 \xb4\xb4 \x81\x81\x81\x81\x81\x9b\x9b \x9c\x9c#" \
    "#\x95\x95\x96\x97\x97\x80\x80\x80\x80\x80 \xb5\xb5\xb6\xb7\xb7 \x81\x81\x81\x81\x81\x9d\x9d\x9e\x9f\x9f#" \
    "#\x95\x95\x96\x97\x97\x80\x80\x80\x80\x80 \xb5\xb5\xb6\xb7\xb7 \x81\x81\x81\x81\x81\x9d\x9d\x9e\x9f\x9f#" \
    "#\x84\x84\x84\x84\x84#################\x83\x83\x83\x83\x83#" \
    "#\x84\x84\x84\x84\x84#ddFeeA***BffOZZ#\x83\x83\x83\x83\x83#" \
    "#\x84\x84\x84\x84\x84#ddFee** **ffOZZ#\x83\x83\x83\x83\x83#" \
    "#\x84\x84\x84\x84\x84#MMKQQ* C *PPS\xde\xde#\x83\x83\x83\x83\x83#" \
    "#\x84\x84\x84\x84\x84#VVLXX** **bbRcc#\x83\x83\x83\x83\x83#" \
    "#     #VVLXXD***EbbRcc#     #" \
    "#\xc0\xc0\xc1\xc2\xc2#\x89\x89\x89\x89\x89TTJWW\x8a\x8a\x8a\x8a\x8a#\xc8\xc8\xc9\xca\xca#" \
    "#\xc0\xc0\xc1\xc2\xc2#\x89\x89\x89\x89\x89TTJWW\x8a\x8a\x8a\x8a\x8a#\xc8\xc8\xc9\xca\xca#" \
    "#\xc3\xc3 \xc4\xc4#\x89\x89\x89\x89\x89GG HH\x8a\x8a\x8a\x8a\x8a#\xcb\xcb \xcc\xcc#" \
    "#\xc5\xc5\xc6\xc7\xc7#\x89\x89\x89\x89\x89YYIgg\x8a\x8a\x8a\x8a\x8a#\xcd\xcd\xce\xcf\xcf#" \
    "#\xc5\xc5\xc6\xc7\xc7#\x89\x89\x89\x89\x89YYIgg\x8a\x8a\x8a\x8a\x8a#\xcd\xcd\xce\xcf\xcf#" \
    "#     #hh\xd0iilltmmpp\xd1qq#     #" \
    "#\x85\x85\x85\x85\x85#hh\xd2iill mmpp\xddqq#\x86\x86\x86\x86\x86#" \
    "#\x85\x85\x85\x85\x85#2y\xd3\xd4\xd5v s w\xd8\xd9x\xdaz#\x86\x86\x86\x86\x86#" \
    "#\x85\x85\x85\x85\x85#jj\xd6kkaa nnoo\xdbrr#\x86\x86\x86\x86\x86#" \
    "#\x85\x85\x85\x85\x85#jj\xd7kkaaunnoo\xdcrr#\x86\x86\x86\x86\x86#" \
    "#\x85\x85\x85\x85\x85######-----######\x86\x86\x86\x86\x86#" \
    "#\xa0\xa0\xa1\xa2\xa2\x88\x88\x88\x88\x88 \xb8\xb8\xb9\xba\xba \x87\x87\x87\x87\x87\xa8\xa8\xa9\xaa\xaa#" \
    "#\xa0\xa0\xa1\xa2\xa2\x88\x88\x88\x88\x88 \xb8\xb8\xb9\xba\xba \x87\x87\x87\x87\x87\xa8\xa8\xa9\xaa\xaa#" \
    "#\xa3\xa3 \xa4\xa4\x88\x88\x88\x88\x88 \xbb\xbb \xbc\xbc \x87\x87\x87\x87\x87\xab\xab \xac\xac#" \
    "#\xa5\xa5\xa6\xa7\xa7\x88\x88\x88\x88\x88 \xbd\xbd\xbe\xbf\xbf \x87\x87\x87\x87\x87\xad\xad\xae\xaf\xaf#" \
    "#\xa5\xa5\xa6\xa7\xa7\x88\x88\x88\x88\x88 \xbd\xbd\xbe\xbf\xbf \x87\x87\x87\x87\x87\xad\xad\xae\xaf\xaf#" \
    "#############################",
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  GNOMEUIINFO_END
};

GnomeUIInfo level_bt_menu[] = {
    /* 42 moves */
  { GNOME_APP_UI_ITEM, N_("1"), NULL, level_cb,
    "1#6#7#" \
    "##..##" \
    "#a..c#" \
    "#aabc#" \
    "#h**d#" \
    "#g**e#" \
    "#gfee#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("4"), NULL, level_cb,
    "4#6#7#" \
    "##..##" \
    "#a..b#" \
    "#cdde#" \
    "#ccee#" \
    "#f**h#" \
    "#g**h#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("8"), NULL, level_cb,
    "8#6#7#" \
    "##..##" \
    "#a..h#" \
    "#bbgh#" \
    "#cbff#" \
    "#c**f#" \
    "#d**e#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("10"), NULL, level_cb,
    "10#6#7#" \
    "##..##" \
    "#a..d#" \
    "#bcdd#" \
    "#ccef#" \
    "#h**f#" \
    "#h**g#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("11"), NULL, level_cb,
    "11#6#7#" \
    "##..##" \
    "#a..c#" \
    "#bbcc#" \
    "#ddfg#" \
    "#d**g#" \
    "#e**h#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

  { GNOME_APP_UI_ITEM, N_("13"), NULL, level_cb,
    "13#6#7#" \
    "##..##" \
    "#a..c#" \
    "#aabb#" \
    "#debg#" \
    "#d**h#" \
    "#f**h#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

 { GNOME_APP_UI_ITEM, N_("16"), NULL, level_cb,
    "16#6#7#" \
    "##..##" \
    "#a..c#" \
    "#abcc#" \
    "#deeh#" \
    "#**eg#" \
    "#**fg#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

 { GNOME_APP_UI_ITEM, N_("17"), NULL, level_cb,
    "17#6#7#" \
    "##..##" \
    "#a..b#" \
    "#ccdd#" \
    "#ecdg#" \
    "#e**g#" \
    "#f**h#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },


 { GNOME_APP_UI_ITEM, N_("19"), NULL, level_cb,
    "19#6#7#" \
    "##..##" \
    "#a..d#" \
    "#abcc#" \
    "#**ce#" \
    "#**gh#" \
    "#fggh#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },


 { GNOME_APP_UI_ITEM, N_("20"), NULL, level_cb,
    "20#6#7#" \
    "##..##" \
    "#a..d#" \
    "#abcd#" \
    "#eegg#" \
    "#e**g#" \
    "#f**i#" \
    "######" ,
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL },

                     /* Dodge i18n for the moment */
  { GNOME_APP_UI_ITEM, "Climb Pro 24", NULL, level_cb,
    "Climb Pro 24#9#11#" \
    "####.####" \
    "#aa...bb#" \
    "#ccdddee#" \
    "#ccfggee#" \
    "#hhffgnn#" \
    "#ihklmno#" \
    "#ijklmpo#" \
    "#jjqqqpp#" \
    "#rrs*tuu#" \
    "#rr***uu#" \
    "#########",
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
                        /* Dodge i18n for the moment. */
  { GNOME_APP_UI_SUBTREE, "Block 10", NULL, level_bt_menu,  NULL,NULL,
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

  int win_width, win_height;

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

  conf_client = gconf_client_get_default ();

  window = gnome_app_new (APPNAME, N_(APPNAME_LONG));

  win_width = gconf_client_get_int (conf_client, "/apps/gnotski/width", NULL);
  win_height = gconf_client_get_int (conf_client, "/apps/gnotski/height", NULL);
  gtk_window_set_default_size(GTK_WINDOW(window), win_width, win_height);
  
  gtk_widget_realize (window);
  
  g_signal_connect (G_OBJECT (window), "delete_event",
                    G_CALLBACK(quit_game_cb), NULL);
  g_signal_connect (G_OBJECT (window), "configure_event",
                    G_CALLBACK(window_resize_cb), NULL);

  gnome_app_create_menus (GNOME_APP (window), main_menu);
  load_image ();
  create_space (); 
  create_statusbar ();

  if (session_xpos >= 0 && session_ypos >= 0)
    gtk_window_move (GTK_WINDOW (window), session_xpos, session_ypos);
    
  gtk_widget_show_all (window);
  new_game_cb (space, NULL);
  
  gtk_main ();
  
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

static gboolean
expose_space (GtkWidget *widget, GdkEventExpose *event)
{
  if (buffer == NULL || clear_buffer)
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
gui_draw_pixmap (char *target, gint x, gint y)
{
  GdkGC *gc;
  GdkColor *bg_color;
  GtkStyle *style;
  GdkColor *fg_color;
  
  gint value;
  gint overlay_size;
  gint overlay_offset;

  gc = space->style->black_gc;
  style = gtk_widget_get_style (space);
  fg_color = &style->fg[GTK_STATE_NORMAL];

  /* blank background */
  bg_color = get_bg_color ();
  gdk_gc_set_foreground (gc, bg_color);
  gdk_color_free (bg_color);
  gdk_draw_rectangle (buffer, gc, TRUE,
                      x * tile_size, y * tile_size,
                      tile_size, tile_size);
  gdk_gc_set_foreground (gc, fg_color);

  if (get_piece_id (target,x,y) != ' ') {
    gdk_draw_pixbuf (buffer, gc, tiles_pixbuf,
                     get_piece_nr (target,x,y) * tile_size, tile_size/2, 
                     x * tile_size, y * tile_size,
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
    gdk_draw_pixbuf (buffer, gc, tiles_pixbuf,
                     value * tile_size + overlay_offset, 
                     overlay_offset + tile_size/2,
                     x * tile_size + overlay_offset, 
                     y * tile_size + overlay_offset, 
                     overlay_size, overlay_size,
                     GDK_RGB_DITHER_NORMAL, 0, 0);
  }

  gtk_widget_queue_draw_area (space, x * tile_size, y * tile_size,
                              tile_size, tile_size);
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
    gtk_widget_set_sensitive (game_menu[4].widget, TRUE);
    g_strfreev (names);
    g_free (scores);
    g_free (scoretimes);
  } else {
    gtk_widget_set_sensitive (game_menu[4].widget, FALSE);
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

static gboolean
configure_pixmaps_idle (void)
{
  if (tile_size != prior_tile_size) {
    if (tiles_pixbuf != NULL) 
      g_object_unref (tiles_pixbuf);
    
    tiles_pixbuf=games_preimage_render (tiles_preimage, tile_size*27,
                                        tile_size*2, NULL);
    prior_tile_size = tile_size;
  }

  if (buffer != NULL)
    g_object_unref(buffer);

  buffer = gdk_pixmap_new (space->window, width * tile_size, 
                           height * tile_size, -1);
  clear_buffer = FALSE;
  redraw_all();
  draw_idle_id = 0;
  return FALSE;
}

static void 
configure_pixmaps (void)
{
  tile_size = MIN ((space_width / width), (space_height / height));
  
  /* Specify tile_size in multiples of 2 to handle double-height SVG theme.*/
  if (tile_size % 2) tile_size--;
  
  if (clear_buffer || (tile_size != prior_tile_size)) {
    if (!draw_idle_id)
      draw_idle_id = g_idle_add ((GSourceFunc) configure_pixmaps_idle, NULL);
    clear_buffer = TRUE;
  }
  
  return;
}

static gboolean
configure_space (GtkWidget *widget, GdkEventConfigure *event)
{
  space_width = event -> width;
  space_height = event -> height;

  configure_pixmaps();
 
  return TRUE;
}

void
create_space (void)
{
  outerframe = gtk_aspect_frame_new (NULL,.5, .5, 1, TRUE);
  gtk_widget_set_size_request (GTK_WIDGET(outerframe), MINWIDTH, MINHEIGHT);
  gnome_app_set_contents (GNOME_APP(window), outerframe);

  gameframe = games_grid_frame_new (9,7);
  gtk_container_add (GTK_CONTAINER(outerframe), gameframe);

  gtk_widget_push_colormap (gdk_rgb_get_colormap());
  space = gtk_drawing_area_new ();
  gtk_widget_pop_colormap ();

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
                                     "gnotski.svg", FALSE, NULL);
  if (g_file_test (fname, G_FILE_TEST_EXISTS)) {
    tiles_preimage = games_preimage_new_from_uri (fname, NULL);
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
  if (image_map[i] == -1){printf ("nr: %i\n",nr);}
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
  char tmp[32];
  char *p = level;
  if (p == NULL) {
    p = level_1_menu[5].user_data;
  }
    
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

  clear_buffer = TRUE;
  set_move (0);

  prepare_map (data);
  
  gtk_aspect_frame_set (GTK_ASPECT_FRAME(outerframe), .5, .5, (gfloat)width/(gfloat)height, FALSE);
  games_grid_frame_set (GAMES_GRID_FRAME(gameframe), width, height);

  configure_pixmaps();

  update_score_state ();
}

void
quit_game_cb (GtkWidget *widget, gpointer data)
{
  gtk_main_quit ();
}

static gboolean
window_resize_cb (GtkWidget *w, GdkEventConfigure *e, gpointer data)
{
  gconf_client_set_int (conf_client, "/apps/gnotski/width",
                        e->width, NULL);
  gconf_client_set_int (conf_client, "/apps/gnotski/height",
                        e->height, NULL);	

  return FALSE;
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
                           "Copyright \xc2\xa9 1999-2004 Lars Rydlinge",
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
