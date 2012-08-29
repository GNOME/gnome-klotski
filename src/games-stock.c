/*
 * Copyright © 2005 Richard Hoelscher
 * Copyright © 2006 Andreas Røsdal
 * Copyright © 2007 Christian Persch
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * Authors:
 *      Richard Hoelscher <rah@rahga.com>
 */

#include <config.h>

#include <string.h>
#include <gtk/gtk.h>
#include <glib/gi18n.h>

#include "games-stock.h"

typedef struct {
  const char *stock_id;
  const char *tooltip;
} GamesStockItemTooltip;

static const char *
games_stock_get_tooltip_from_stockid (const char* stockid)
{
  static const GamesStockItemTooltip stock_item_tooltip[] = {
    { GAMES_STOCK_CONTENTS,         N_("View help for this game") },
    { GAMES_STOCK_END_GAME,         N_("End the current game") },
    { GAMES_STOCK_FULLSCREEN,       N_("Toggle fullscreen mode") },
    { GAMES_STOCK_HINT,             N_("Get a hint for your next move") },
    { GAMES_STOCK_LEAVE_FULLSCREEN, N_("Leave fullscreen mode") },
    { GAMES_STOCK_NETWORK_GAME,     N_("Start a new multiplayer network game") },
    { GAMES_STOCK_NETWORK_LEAVE,    N_("End the current network game and return to network server") },
    { GAMES_STOCK_NEW_GAME,         N_("Start a new game") },
    { GAMES_STOCK_PAUSE_GAME,       N_("Pause the game") },
    { GAMES_STOCK_PLAYER_LIST,      N_("Show a list of players in the network game") },
    { GAMES_STOCK_REDO_MOVE,        N_("Redo the undone move") },
    { GAMES_STOCK_RESTART_GAME,     N_("Restart the game") },
    { GAMES_STOCK_RESUME_GAME,      N_("Resume the paused game") },
    { GAMES_STOCK_SCORES,           N_("View the scores") },
    { GAMES_STOCK_UNDO_MOVE,        N_("Undo the last move") },
    { GTK_STOCK_ABOUT,              N_("About this game") },
    { GTK_STOCK_CLOSE,              N_("Close this window") },
    { GTK_STOCK_PREFERENCES,        N_("Configure the game") },
    { GTK_STOCK_QUIT,               N_("Quit this game") },
  };

  guint i;
  const char *tooltip = NULL;

  if (!stockid)
    return NULL;

  for (i = 0; i < G_N_ELEMENTS (stock_item_tooltip); i++) {
    if (strcmp (stock_item_tooltip[i].stock_id, stockid) == 0) {
      tooltip = stock_item_tooltip[i].tooltip;
      break;
    }
  }

  return tooltip ? _(tooltip) : NULL;
}

static void
menu_item_select_cb (GtkWidget * widget, GtkStatusbar * statusbar)
{
  GtkAction *action;
  gchar *tooltip;
  guint context_id;

  context_id = gtk_statusbar_get_context_id (statusbar, "games-tooltip");

  action = gtk_activatable_get_related_action (GTK_ACTIVATABLE (widget));
  g_return_if_fail (action != NULL);

  g_object_get (action, "tooltip", &tooltip, NULL);

  if (tooltip) {
    gtk_statusbar_push (statusbar, context_id, tooltip);
    g_free (tooltip);
  } else {
    const gchar *stock_tip = NULL;
    gchar *stockid;

    g_object_get (action, "stock-id", &stockid, NULL);
    if (stockid != NULL) {
      stock_tip = games_stock_get_tooltip_from_stockid (stockid);
      g_free (stockid);
    }

    if (stock_tip != NULL) {
      gtk_statusbar_push (statusbar, context_id, stock_tip);
    }
  }
}

static void
menu_item_deselect_cb (GtkWidget * widget, GtkStatusbar * statusbar)
{
  guint context_id;

  context_id = gtk_statusbar_get_context_id (statusbar, "games-tooltip");
  gtk_statusbar_pop (statusbar, context_id);
}

static void
connect_proxy_cb (GtkUIManager * ui_manager,
                  GtkAction * action,
                  GtkWidget * proxy, GtkWidget * statusbar)
{
  if (!GTK_IS_MENU_ITEM (proxy))
    return;

  g_signal_connect (proxy, "select",
                    G_CALLBACK (menu_item_select_cb), statusbar);
  g_signal_connect (proxy, "deselect",
                    G_CALLBACK (menu_item_deselect_cb), statusbar);
}

static void
disconnect_proxy_cb (GtkUIManager * ui_manager,
                     GtkAction * action,
                     GtkWidget * proxy, GtkWidget * statusbar)
{
  if (!GTK_IS_MENU_ITEM (proxy))
    return;

  g_signal_handlers_disconnect_by_func
    (proxy, G_CALLBACK (menu_item_select_cb), statusbar);
  g_signal_handlers_disconnect_by_func
    (proxy, G_CALLBACK (menu_item_deselect_cb), statusbar);
}

/** 
 *  Call this once, after creating the UI Manager but before 
 *  you start adding actions. Then, whenever an action is added, 
 *  connect_proxy() will set tooltips to be displayed in the statusbar.
 */
void
games_stock_prepare_for_statusbar_tooltips (GtkUIManager * ui_manager,
                                            GtkWidget * statusbar)
{
  g_signal_connect (ui_manager, "connect-proxy",
                    G_CALLBACK (connect_proxy_cb), statusbar);
  g_signal_connect (ui_manager, "disconnect-proxy",
                    G_CALLBACK (disconnect_proxy_cb), statusbar);
}

static void
register_stock_icon (GtkIconFactory * icon_factory,
                     const char * stock_id,
                     const char * icon_name)
{
  GtkIconSource *source;
  GtkIconSet *set;

  set = gtk_icon_set_new ();

  source = gtk_icon_source_new ();
  gtk_icon_source_set_icon_name (source, icon_name);
  gtk_icon_set_add_source (set, source);
  gtk_icon_source_free (source);

  gtk_icon_factory_add (icon_factory, stock_id, set);
  gtk_icon_set_unref (set);
}

static void
register_stock_icon_bidi (GtkIconFactory * icon_factory,
                          const char * stock_id,
                          const char * icon_name_ltr,
                          const char * icon_name_rtl)
{
  GtkIconSource *source;
  GtkIconSet *set;

  set = gtk_icon_set_new ();

  source = gtk_icon_source_new ();
  gtk_icon_source_set_icon_name (source, icon_name_ltr);
  gtk_icon_source_set_direction (source, GTK_TEXT_DIR_LTR);
  gtk_icon_source_set_direction_wildcarded (source, FALSE);
  gtk_icon_set_add_source (set, source);
  gtk_icon_source_free (source);

  source = gtk_icon_source_new ();
  gtk_icon_source_set_icon_name (source, icon_name_rtl);
  gtk_icon_source_set_direction (source, GTK_TEXT_DIR_RTL);
  gtk_icon_source_set_direction_wildcarded (source, FALSE);
  gtk_icon_set_add_source (set, source);
  gtk_icon_source_free (source);

  gtk_icon_factory_add (icon_factory, stock_id, set);
  gtk_icon_set_unref (set);
}

void
games_stock_init (void)
{
  /* These stocks have a gtk stock icon */
  const char *stock_icon_aliases[][2] = {
    { GAMES_STOCK_CONTENTS,         "help-contents" },
    { GAMES_STOCK_HINT,             "dialog-information" },
    { GAMES_STOCK_NEW_GAME,         "document-new" },
    { GAMES_STOCK_START_NEW_GAME,   "document-new" },
    { GAMES_STOCK_RESET,            "edit-clear" },
    { GAMES_STOCK_RESTART_GAME,     "view-refresh" },
    { GAMES_STOCK_FULLSCREEN,       "view-fullscreen" },
    { GAMES_STOCK_LEAVE_FULLSCREEN, "view-restore" },
    { GAMES_STOCK_NETWORK_GAME,     "network-idle" },
    { GAMES_STOCK_NETWORK_LEAVE,    "process-stop" },
    { GAMES_STOCK_PLAYER_LIST,      "dialog-information" },
    { GAMES_STOCK_PAUSE_GAME,       "media-playback-pause" },
  };

  const char *stock_icon_aliases_bidi[][3] = {
    { GAMES_STOCK_REDO_MOVE, "edit-redo", "edit-undo" },
    { GAMES_STOCK_UNDO_MOVE, "edit-undo", "edit-redo" },
    { GAMES_STOCK_RESUME_GAME, "media-playback-start", "media-playback-start" },
  };

  /* Private icon names */
  const char *private_icon_names[][2] = {
    { GAMES_STOCK_TELEPORT, "teleport" },
    { GAMES_STOCK_RTELEPORT, "teleport-random" },
    { GAMES_STOCK_SCORES, "scores" },
    { GAMES_STOCK_DEAL_CARDS, "cards-deal" }
  };

/* Use different accels on GTK/GNOME and Maemo */

  static const GtkStockItem games_stock_items[] = {
    { GAMES_STOCK_CONTENTS,         N_("_Contents"),          0, GDK_KEY_F1, NULL },
    { GAMES_STOCK_FULLSCREEN,       N_("_Fullscreen"),        0, GDK_KEY_F11, NULL },
    { GAMES_STOCK_HINT,             N_("_Hint"),              GDK_CONTROL_MASK, 'h', NULL },
    /* Translators: This "_New" is for the menu item 'Game->New', implies "New Game" */
    { GAMES_STOCK_NEW_GAME,         N_("_New"),               GDK_CONTROL_MASK, 'n', NULL },
    /* Translators: This "_New Game" is for the game-over dialogue */
    { GAMES_STOCK_START_NEW_GAME,   N_("_New Game"),          0, 0, NULL },
    { GAMES_STOCK_REDO_MOVE,        N_("_Redo Move"),         GDK_CONTROL_MASK | GDK_SHIFT_MASK, 'z', NULL },
    /* Translators: this is the "Reset" scores button in a scores dialogue */
    { GAMES_STOCK_RESET,            N_("_Reset"),             0, 0, NULL },
    /* Translators: "_Restart" is the menu item 'Game->Restart', implies "Restart Game" */
    { GAMES_STOCK_RESTART_GAME,     N_("_Restart"),           0, 0, NULL },
    { GAMES_STOCK_UNDO_MOVE,        N_("_Undo Move"),         GDK_CONTROL_MASK, 'z', NULL },
    { GAMES_STOCK_DEAL_CARDS,       N_("_Deal"),              GDK_CONTROL_MASK, 'd', NULL },
    { GAMES_STOCK_LEAVE_FULLSCREEN, N_("_Leave Fullscreen"),  0, GDK_KEY_F11, NULL },
    { GAMES_STOCK_NETWORK_GAME,     N_("Network _Game"),      GDK_CONTROL_MASK, 'g', NULL },
    { GAMES_STOCK_NETWORK_LEAVE,    N_("L_eave Game"),        GDK_CONTROL_MASK, 'e', NULL },
    { GAMES_STOCK_PLAYER_LIST,      N_("Player _List"),       GDK_CONTROL_MASK, 'l', NULL },
    { GAMES_STOCK_PAUSE_GAME,       N_("_Pause"),             0, GDK_KEY_Pause, NULL },
    { GAMES_STOCK_RESUME_GAME,      N_("Res_ume"),            0, GDK_KEY_Pause, NULL },
    { GAMES_STOCK_SCORES,           N_("_Scores"),            0, 0, NULL },
    { GAMES_STOCK_END_GAME,         N_("_End Game"),          0, 0, NULL },
  };

  guint i;
  GtkIconFactory *icon_factory;

  icon_factory = gtk_icon_factory_new ();

  for (i = 0; i < G_N_ELEMENTS (stock_icon_aliases); ++i) {
    register_stock_icon (icon_factory,
                         stock_icon_aliases[i][0],
                         stock_icon_aliases[i][1]);
  }

  for (i = 0; i < G_N_ELEMENTS (stock_icon_aliases_bidi); ++i) {
    register_stock_icon_bidi (icon_factory,
                              stock_icon_aliases_bidi[i][0],
                              stock_icon_aliases_bidi[i][1],
                              stock_icon_aliases_bidi[i][2]);
  }

  /* Register our private themeable icons */
  for (i = 0; i < G_N_ELEMENTS (private_icon_names); i++) {
    register_stock_icon (icon_factory,
                         private_icon_names[i][0],
                         private_icon_names[i][1]);
  }

  gtk_icon_factory_add_default (icon_factory);
  g_object_unref (icon_factory);

  /* GtkIconTheme will then look in our custom hicolor dir
   * for icons as well as the standard search paths.
   */
  /* FIXME: multi-head! */
  gtk_icon_theme_append_search_path (gtk_icon_theme_get_default (), ICON_THEME_DIRECTORY);
 
  gtk_stock_add_static (games_stock_items, G_N_ELEMENTS (games_stock_items));
}

/* Returns a GPL N+ license string for a specific game. */
static gchar *
games_get_license_version (const gchar * game_name,
                           int version)
{
  gchar *license_trans, *license_str;

  static const char license0[] =
    /* %s is replaced with the name of the game in gnome-games. */
    N_("%s is free software; you can redistribute it and/or modify "
       "it under the terms of the GNU General Public License as published by "
       "the Free Software Foundation; either version %d of the License, or "
       "(at your option) any later version.");
  static const char license1[] =
    N_("%s is distributed in the hope that it will be useful, "
       "but WITHOUT ANY WARRANTY; without even the implied warranty of "
       "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the "
       "GNU General Public License for more details.");
  static const char license2[] =
    N_("You should have received a copy of the GNU General Public License "
       "along with %s; if not, write to the Free Software Foundation, Inc., "
       "51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA");
  static const char license3[] =
    N_("You should have received a copy of the GNU General Public License "
       "along with this program.  If not, see <http://www.gnu.org/licenses/>.");

  if (version >= 3)
    license_trans = g_strjoin ("\n\n", _(license0), _(license1), _(license3), NULL);
  else
    license_trans = g_strjoin ("\n\n", _(license0), _(license1), _(license2), NULL);

  license_str =
    g_strdup_printf (license_trans, game_name, version, game_name, game_name);
  g_free (license_trans);

  return license_str;
}

/**
 * gamess_get_licence:
 *
 * Returns: a newly allocated string with a GPL licence notice. The GPL version used
 *   depends on the game and the configure options and is determined from
 *   games_runtime_get_gpl_version()
 */
gchar *
games_get_license (const gchar * game_name)
{
  return games_get_license_version (game_name, 2);
}
