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
#include <libgnomeui/gnome-window-icon.h>
#include "pieces.h"

#define APPNAME "gnotski"
#define APPNAME_LONG "Gnome Klotski"

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
GdkPixmap *tiles_pixmap = NULL;

GdkColor bg_color;

char *map = NULL;
char *tmpmap = NULL;
char *move_map = NULL;
char *orig_map = NULL;

gint statusbar_id,height=-1,width=-1,moves=0;

int session_flag = 0;
int session_xpos = 0;
int session_ypos = 0;
int session_position  = 0;

char current_level[16];

void create_window();
void create_space();
void create_statusbar();

void redraw_all();
void message(gchar *);
void load_image();
void gui_draw_pixmap(char *, gint, gint);
int get_piece_nr(char *,int,int);
int get_piece_id(char *,int,int);
void set_piece_id(char *,int,int,int);
int check_valid_move(int, int, int);
int do_move_piece(int, int, int);
int move_piece(int,int,int,int,int);
void copymap(char *,char *);
int mapcmp(char *,char *);
static int save_state(GnomeClient *,gint, GnomeRestartStyle, gint,
                      GnomeInteractStyle, gint fast, gpointer);
void print_map(char *);
void set_move(int);
void new_move();
int game_over();
void game_score();

/* ------------------------- MENU ------------------------ */
void new_game_cb(GtkWidget *, gpointer);
void quit_game_cb(GtkWidget *, gpointer);
void level_cb(GtkWidget *, gpointer);
void about_cb(GtkWidget *, gpointer);
void score_cb(GtkWidget *, gpointer);

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
    NULL, GNOME_APP_PIXMAP_DATA, NULL, 0, 0, NULL }, */

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
    GNOME_APP_PIXMAP_STOCK, GNOME_STOCK_MENU_BLANK, 
    (GdkModifierType) 0, GDK_CONTROL_MASK },
  { GNOME_APP_UI_SUBTREE, N_("_Medium"), NULL, level_2_menu,  NULL,NULL,
    GNOME_APP_PIXMAP_STOCK, GNOME_STOCK_MENU_BLANK, 
    (GdkModifierType) 0, GDK_CONTROL_MASK },
  { GNOME_APP_UI_SUBTREE, N_("_Advanced"), NULL, level_3_menu,  NULL,NULL,
    GNOME_APP_PIXMAP_STOCK, GNOME_STOCK_MENU_BLANK,
    (GdkModifierType) 0, GDK_CONTROL_MASK },
  GNOMEUIINFO_MENU_SCORES_ITEM (score_cb, NULL),
  GNOMEUIINFO_SEPARATOR,
  GNOMEUIINFO_MENU_EXIT_ITEM (quit_game_cb, NULL),
  GNOMEUIINFO_END
};

GnomeUIInfo help_menu[] = {
  GNOMEUIINFO_HELP("gnotski"),
  GNOMEUIINFO_MENU_ABOUT_ITEM(about_cb, NULL),
  GNOMEUIINFO_END
};

GnomeUIInfo main_menu[] = {
  GNOMEUIINFO_MENU_GAME_TREE(game_menu),
  GNOMEUIINFO_MENU_HELP_TREE(help_menu),
  GNOMEUIINFO_END
};

static const struct poptOption options[] = {
  { NULL, 'x', POPT_ARG_INT, &session_xpos, 0, NULL, NULL },
  { NULL, 'y', POPT_ARG_INT, &session_ypos, 0, NULL, NULL },
  { NULL, '\0', 0, NULL, 0 }
};

/* ------------------------------------------------------- */

int main (int argc, char **argv){
  GnomeClient *client;

  gnome_score_init(APPNAME);
  bindtextdomain(PACKAGE, GNOMELOCALEDIR);
  textdomain(PACKAGE);
   
  gnome_init_with_popt_table(APPNAME, VERSION, argc, argv, options, 0, NULL);
  gnome_window_icon_set_default_from_file (GNOME_ICONDIR"/gnotski-icon.png");
  client = gnome_master_client();
  gtk_object_ref(GTK_OBJECT(client));
  gtk_object_sink(GTK_OBJECT(client));
  
  gtk_signal_connect(GTK_OBJECT (client), "save_yourself", 
		     GTK_SIGNAL_FUNC (save_state), argv[0]);
  gtk_signal_connect(GTK_OBJECT(client), "die", GTK_SIGNAL_FUNC(quit_game_cb),
		     argv[0]);

  create_window();
  gnome_app_create_menus(GNOME_APP(window), main_menu);
  load_image();
  create_space(); 
  create_statusbar();

  if(session_xpos >= 0 && session_ypos >= 0)
    gtk_widget_set_uposition(window, session_xpos, session_ypos);
    
  gtk_widget_show(window);
  new_game_cb(space,NULL);
  
  gtk_main ();
  
/*  gtk_object_unref(GTK_OBJECT(client)); */
  return 0;
}

void create_window(){
  window = gnome_app_new(APPNAME, N_(APPNAME_LONG));
  gtk_window_set_policy(GTK_WINDOW(window), FALSE, FALSE, TRUE);
  gtk_widget_realize(window);
  gtk_signal_connect(GTK_OBJECT(window), "delete_event", 
		     GTK_SIGNAL_FUNC(quit_game_cb), NULL);
}

gint expose_space(GtkWidget *widget, GdkEventExpose *event){ 
  gdk_draw_pixmap(widget->window, 
                  widget->style->fg_gc[GTK_WIDGET_STATE(widget)], 
                  buffer, event->area.x, event->area.y, 
                  event->area.x, event->area.y, 
                  event->area.width, event->area.height);
  return FALSE; 
}

void redraw_all(){
  int x,y;
  for(y = 0; y < height; y++)
    for(x = 0; x < width; x++)
      gui_draw_pixmap(map, x, y);
}

int movable(int id){
  if(!(id == '#' || id == '.' || id == ' ' || id == '-'))
     return 1;
  return 0;
}

int button_down = 0;
int piece_id = -1;
int piece_x = 0; 
int piece_y = 0; 

gint button_press_space(GtkWidget *widget, GdkEventButton *event){ 
  if(event->button == 1){
    if(game_over())
      return FALSE;
    button_down = 1;
    piece_x = (int) event->x/TILE_SIZE;
    piece_y = (int) event->y/TILE_SIZE;
    piece_id = get_piece_id(map,piece_x,piece_y); 
    copymap(move_map,map);
  }
  return FALSE;
}

gint button_release_space(GtkWidget *widget, GdkEventButton *event){ 
  if(event->button == 1){
    if(button_down == 1){
      if(movable(piece_id))
	if(mapcmp(move_map,map)){
	  new_move();
	  if(game_over()){
	    message(_("Level completed. Well done."));
	    game_score();
	  }
	}
      button_down = 0;
    }
  }
  return FALSE;
}

gint button_motion_space(GtkWidget *widget, GdkEventButton *event){ 
  int new_piece_x, new_piece_y;
  if(button_down == 1){
    new_piece_x = (int) event->x/TILE_SIZE;
    new_piece_y = (int) event->y/TILE_SIZE;
    if(new_piece_x >= width || event->x < 0 ||
       new_piece_y >= height || event->y < 0) return FALSE;
    if(movable(piece_id))
      if(move_piece(piece_id,piece_x, piece_y, new_piece_x, new_piece_y)==1){
	piece_x = new_piece_x; piece_y = new_piece_y;
      }
    return TRUE;
  }
  return FALSE;
}

void gui_draw_pixmap(char *target, gint x, gint y){
  GdkRectangle area;
  int value;
  
  gdk_draw_pixmap(buffer, space->style->black_gc, tiles_pixmap,
		  get_piece_nr(target,x,y)*TILE_SIZE, 0, 
		  x*TILE_SIZE, y*TILE_SIZE, TILE_SIZE, TILE_SIZE);
  if(get_piece_id(target,x,y)=='*'){
    if(get_piece_id(orig_map,x,y)=='.')
      value = 20;
    else
      value = 22;
    gdk_draw_pixmap(buffer, space->style->black_gc, tiles_pixmap,
		    value*TILE_SIZE+10,10,
		    x*TILE_SIZE+10, y*TILE_SIZE+10,8,8);
  }
  area.x = x*TILE_SIZE; area.y = y*TILE_SIZE; 
  area.width = TILE_SIZE; area.height = TILE_SIZE;
  gtk_widget_draw (space, &area);
}

void score_cb(GtkWidget *widget, gpointer data){
  gnome_scores_display (_(APPNAME_LONG), APPNAME, current_level, 0);
}

void game_score(){
  gint pos;
  pos = gnome_score_log(moves,current_level,FALSE);
  gnome_scores_display(_(APPNAME_LONG), APPNAME, current_level, pos);
}

gint configure_space(GtkWidget *widget, GdkEventConfigure *event){
  if(width>0){
    if(buffer)
      gdk_pixmap_unref(buffer);
    buffer = gdk_pixmap_new(widget->window, widget->allocation.width, 
			    widget->allocation.height, -1);
    redraw_all();
  }
  return(TRUE);
}

void create_space(){
  gtk_widget_push_visual(gdk_imlib_get_visual());
  gtk_widget_push_colormap(gdk_imlib_get_colormap());
  space = gtk_drawing_area_new();
  gtk_widget_pop_colormap();
  gtk_widget_pop_visual();
  gnome_app_set_contents(GNOME_APP(window),space);
  gtk_drawing_area_size(GTK_DRAWING_AREA(space),
			TILE_SIZE*width,TILE_SIZE*height); 
  gtk_widget_set_events(space, GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK |
			GDK_POINTER_MOTION_MASK | GDK_BUTTON_RELEASE_MASK);
  gtk_widget_realize(space);
  gtk_signal_connect(GTK_OBJECT(space), "expose_event", 
                     GTK_SIGNAL_FUNC(expose_space), NULL);
  gtk_signal_connect(GTK_OBJECT(space), "configure_event", 
                     GTK_SIGNAL_FUNC(configure_space), NULL);
  gtk_signal_connect(GTK_OBJECT(space), "button_press_event", 
                     GTK_SIGNAL_FUNC(button_press_space), NULL);
  gtk_signal_connect (GTK_OBJECT(space),"button_release_event",
                      GTK_SIGNAL_FUNC(button_release_space), NULL);
  gtk_signal_connect (GTK_OBJECT(space), "motion_notify_event",
                      GTK_SIGNAL_FUNC(button_motion_space), NULL);
  gtk_widget_show(space);
}

void create_statusbar(){
  GtkWidget *move_label,*move_box;
  move_box = gtk_hbox_new(0, FALSE);
  move_label = gtk_label_new (_("Moves:"));
  gtk_box_pack_start (GTK_BOX(move_box), move_label, FALSE, FALSE, 0);
  move_value = gtk_label_new ("000");
  gtk_box_pack_start (GTK_BOX(move_box), move_value, FALSE, FALSE, 0);
  gtk_widget_show (move_label); gtk_widget_show (move_value); 
  gtk_widget_show (move_box);

  statusbar = gtk_statusbar_new();
  statusbar_id = gtk_statusbar_get_context_id(GTK_STATUSBAR(statusbar),
					      APPNAME);
  gtk_box_pack_end(GTK_BOX(statusbar), move_box, FALSE, FALSE, 0);
  gnome_app_set_statusbar(GNOME_APP(window), statusbar);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar), statusbar_id,APPNAME_LONG);
}

void message(gchar *message){
  gtk_statusbar_pop(GTK_STATUSBAR(statusbar), statusbar_id);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar), statusbar_id, message);
}

void load_image(){
  char *fname;
  GdkImlibImage *image;
  GdkVisual *visual;

  fname = gnome_unconditional_pixmap_file("gnotski.png");
  if(!g_file_exists(fname)) {
    g_print(_("Could not find \'%s\' pixmap file\n"), fname); exit(1);
  }
  image = gdk_imlib_load_image(fname);
  visual = gdk_imlib_get_visual();
  if(visual->type != GDK_VISUAL_TRUE_COLOR) {
    gdk_imlib_set_render_type(RT_PLAIN_PALETTE);
  }
  gdk_imlib_render(image, image->rgb_width, image->rgb_height);
  tiles_pixmap = gdk_imlib_move_image(image);
  gdk_imlib_destroy_image(image);
  g_free(fname);
}

void set_move(int x){
  moves = x-1;
  new_move();
}

void new_move() {
  char str[4];
  if(moves<999) moves++;
  sprintf(str,"%03d", moves);
  gtk_label_set(GTK_LABEL(move_value), str);
}


void print_map(char *src){
  int x,y;
  for(y=0; y<height; y++){
    for(x=0; x<width; x++)
      printf("%c", get_piece_id(src,x,y));
    printf("\n");
  }
}

int game_over(){
  int x,y, over=1;
  for(y=0; y<height; y++)
    for(x=0; x<width; x++)
      if(get_piece_id(map,x,y) == '*' && get_piece_id(orig_map,x,y) != '.')
	over = 0;
  return over;
}

int do_move_piece(int id, int dx, int dy){
  int x,y;
  copymap(tmpmap,map);

  /* Move pieces */
  for(y=0; y<height; y++)
    for(x=0; x<width; x++)
      if(get_piece_id(tmpmap,x,y) == id)
	set_piece_id(tmpmap,x,y,' ');

  for(y=0; y<height; y++)
    for(x=0; x<width; x++)
      if(get_piece_id(map,x,y) == id)
	set_piece_id(tmpmap,(x+dx),(y+dy),id);

  /* Preserve some from original map */
  for(y=0; y<height; y++)
    for(x=0; x<width; x++){
      if(get_piece_id(tmpmap,x,y)==' ' && get_piece_id(orig_map,x,y)=='.')
	set_piece_id(tmpmap,x,y,'.');
      if(get_piece_id(tmpmap,x,y)==' ' && get_piece_id(orig_map,x,y)=='-')
	set_piece_id(tmpmap,x,y,'-');
    }
  /* Paint changes */
  for(y=0; y<height; y++)
    for(x=0; x<width; x++)
      if(get_piece_id(map,x,y) != get_piece_id(tmpmap,x,y) ||
	 get_piece_id(tmpmap,x,y) == id)
	gui_draw_pixmap(tmpmap, x, y);

  copymap(map,tmpmap);
  return 1;
}

int check_valid_move(int id, int dx, int dy){
  int x,y,valid = 1;
  for(y=0; y<height; y++)
    for(x=0; x<width; x++)
      if(get_piece_id(map,x,y) == id)
	if(!(get_piece_id(map,x+dx,y+dy) == ' ' ||
	     get_piece_id(map,x+dx,y+dy) == '.' ||
	     get_piece_id(map,x+dx,y+dy) == id ||
	   (id == '*' && get_piece_id(map,x+dx,y+dy) == '-'))){
	  valid = 0;
	}
  return valid;
}

int move_piece(int id,int x1,int y1,int x2,int y2){
  int return_value = 0;

  if(get_piece_id(map,x2,y2) == id)
    return_value = 1;

  if(!((abs(y1-y2)==0 && abs(x1-x2)==1) || (abs(x1-x2)==0 && abs(y1-y2)==1)))
    return 0;

  if(abs(y1-y2)==1){
    if(y1-y2<0) 
      if(check_valid_move(id,0,1))
	return do_move_piece(id,0,1);
    if(y1-y2>0) 
      if(check_valid_move(id,0,-1))
	return do_move_piece(id,0,-1);
  }
  if(abs(x1-x2)==1){
    if(x1-x2<0) 
      if(check_valid_move(id,1,0))
	return do_move_piece(id,1,0);
    if(x1-x2>0) 
      if(check_valid_move(id,-1,0))
	return do_move_piece(id,-1,0);
  }
  return return_value;;
}

int get_piece_id(char *src, int x, int y){
  return src[x + 1 + (y + 1) * (width+2)];
}

void set_piece_id(char *src, int x, int y, int id){
  src[x + 1 + (y + 1) * (width+2)] = id;
}


int get_piece_nr(char *src, int x,int y){
  char c;
  int i=0, nr = 0;
  x++; y++;
  c = src[x + y * (width+2)];
  if(c=='-') return 23;
  if(c==' ') return 21;
  if(c=='.') return 20;

  nr += 1   * (src[(x - 1) + (y - 1) * (width+2)] == c);
  nr += 2   * (src[(x - 0) + (y - 1) * (width+2)] == c);
  nr += 4   * (src[(x + 1) + (y - 1) * (width+2)] == c);
  nr += 8   * (src[(x - 1) + (y - 0) * (width+2)] == c);
  nr += 16  * (src[(x + 1) + (y - 0) * (width+2)] == c);
  nr += 32  * (src[(x - 1) + (y + 1) * (width+2)] == c);
  nr += 64  * (src[(x - 0) + (y + 1) * (width+2)] == c);
  nr += 128 * (src[(x + 1) + (y + 1) * (width+2)] == c);
  while(nr != image_map[i] && image_map[i] != -1) i+=2;
  return image_map[i+1];
}

int mapcmp(char *m1, char *m2){
  int x,y;
  for(y=0; y<height; y++)
    for(x=0; x<width; x++)
      if(get_piece_id(m1,x,y) != get_piece_id(m2,x,y))
	return 1;
  return 0;
}

void copymap(char *dest,char *src){
  memcpy(dest,src,(width+2)*(height+1));
}

void prepare_map(char *level){
  int x,y,i=0;
  static int first = 1;
  char tmp[32];
  char *p = level;

  if(p==NULL){
    if(first){
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
      message(_("Welcome to Gnome Klotski"));
    } else {
      return;
    }
  } else {
    while(i<16 && *p != '#')
      current_level[i++] = *p++;
    current_level[i] = '\0'; p++;
    
    i = 0; 
    while(i<16 && *p != '#') tmp[i++] = *p++;
    tmp[i] = '\0'; width = atoi(tmp); p++;
    
    i = 0; 
    while(i<16 && *p != '#') tmp[i++] = *p++;
    tmp[i] = '\0'; height = atoi(tmp); p++;
    
    sprintf(tmp,_("Playing level %s"),current_level);
    
    message(tmp);
  }

  if(map){
    free(map);
    free(tmpmap);
    free(move_map);
    free(orig_map);
  }

  map = calloc(1,(width+2)*(height+2));
  tmpmap = calloc(1,(width+2)*(height+2));
  orig_map = calloc(1,(width+2)*(height+2));
  move_map = calloc(1,(width+2)*(height+2));
  if(p!=NULL)
    for(y=0; y<height; y++)
      for(x=0; x<width; x++)
	set_piece_id(map,x,y,*p++);
  copymap(orig_map,map);
}


void new_game_cb(GtkWidget *widget, gpointer data){
  widget = space;

  prepare_map(data);
  gtk_drawing_area_size(GTK_DRAWING_AREA(space),
			width*TILE_SIZE,height*TILE_SIZE);
  gtk_widget_realize(window);

  set_move(0);
}

void quit_game_cb(GtkWidget *widget, gpointer data){
  if(buffer)
    gdk_pixmap_unref(buffer);
  if(tiles_pixmap)
    gdk_pixmap_unref(tiles_pixmap);

  gtk_main_quit();
}

static char *nstr(int n){
  char buf[20]; sprintf(buf, "%d", n);
  return strdup(buf);
}

static int save_state(GnomeClient *client,gint phase, 
                      GnomeRestartStyle save_style, gint shutdown,
                      GnomeInteractStyle interact_style, gint fast,
                      gpointer client_data){
  char *argv[20];
  int i;
  gint xpos, ypos;
  
  gdk_window_get_origin(window->window, &xpos, &ypos);
  
  i = 0;
  argv[i++] = (char *)client_data;
  argv[i++] = "-x";
  argv[i++] = nstr(xpos);
  argv[i++] = "-y";
  argv[i++] = nstr(ypos);
  
  gnome_client_set_restart_command(client, i, argv);
  gnome_client_set_clone_command(client, 0, NULL);
  
  free(argv[2]);
  free(argv[4]);
  return TRUE;
}

void level_cb(GtkWidget *widget, gpointer data){
  new_game_cb(space,data);
}

void about_cb(GtkWidget *widget, gpointer data){
  GtkWidget *about;
  
  const gchar *authors[] = { "Lars Rydlinge", NULL };
  about = gnome_about_new(_(APPNAME_LONG), 
                          VERSION, 
                          "(C) 1999 Lars Rydlinge",
			  (const char **)authors, 
			  _("Klotski clone\n" \
			    "(Comments to: Lars.Rydlinge@HIG.SE)"), 
                          NULL);
  gtk_widget_show(about);
}
