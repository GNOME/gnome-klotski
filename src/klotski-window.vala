/*
   This file is part of GNOME Klotski.

   Copyright (C) 2010-2013 Robert Ancell

   GNOME Klotski is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   GNOME Klotski is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with GNOME Klotski.  If not, see <https://www.gnu.org/licenses/>.
*/

using Gtk;

[GtkTemplate (ui = "/org/gnome/Klotski/ui/klotski.ui")]
private class KlotskiWindow : ApplicationWindow
{
    /* Puzzle Info */
    private struct LevelInfo
    {
        string  name;
        uint8   group;
        uint8   width;
        uint8   height;
        string  data;
    }

    /* Settings */
    private GLib.Settings settings;

    private int window_width = 0;
    private int window_height = 0;
    private bool window_is_fullscreen = false;
    private bool window_is_maximized = false;
    private bool window_is_tiled = false;

    private const string KEY_LEVEL = "level";

    /* Widgets */
    [GtkChild] private unowned HeaderBar headerbar;
    [GtkChild] private unowned Stack stack_packs;
    [GtkChild] private unowned Stack stack_puzzles;
    [GtkChild] private unowned Popover puzzles_popover;
    [GtkChild] private unowned MenuButton game_menubutton;
    [GtkChild] private unowned MenuButton main_menubutton;
    private PuzzleView view;

    [GtkChild] private unowned TreeView treeview_huarong;
    [GtkChild] private unowned TreeView treeview_challenge;
    [GtkChild] private unowned TreeView treeview_skill;

    [GtkChild] private unowned Grid main_grid;
    [GtkChild] private unowned Button unfullscreen_button;

    /* Actions, to disable or enable */
    private SimpleAction prev_pack;
    private SimpleAction next_pack;
    private SimpleAction prev_puzzle;
    private SimpleAction next_puzzle;
    private SimpleAction start_game;

    /* The game being played */
    private bool puzzle_init_done = false;
    private Puzzle puzzle;

    private int current_pack = -1;
    private int current_level = -1;

    private Games.Scores.Context scores_context;

    /* The "puzzle name" remarks provide context for translation. Add new
     * puzzles at the end, or you'll mess up saved scores.
     */
    private Gtk.ListStore liststore_huarong;
    private Gtk.ListStore liststore_challenge;
    private Gtk.ListStore liststore_skill;
    private TreeIter [] puzzles_items;

    private static Gee.List<Games.Scores.Category> score_categories;
    /* Warning: reordering these will screw up import of old scores. */
    private const LevelInfo levels [] =
    {
        /* Translators: puzzle name */
        {   N_("Only 18 Steps"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#m**n#" +
            "#cdef#" +
            "#ghij#" +
            "#k  l#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Daisy"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdef#" +
            "#zghi#" +
            "#j  k#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Violet"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdef#" +
            "#cghi#" +
            "#j  k#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Poppy"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdde#" +
            "#fghi#" +
            "#j  k#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Pansy"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdef#" +
            "#cghf#" +
            "#i  j#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Snowdrop"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdde#" +
            "#cfgh#" +
            "#i  j#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name — sometimes called by french name "L’Âne Rouge" (with the same meaning) */
        {   N_("Red Donkey"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdde#" +
            "#cfge#" +
            "#h  i#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Trail"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**c#" +
            "#a**c#" +
            "#eddg#" +
            "#hffj#" +
            "# ii #" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Ambush"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**c#" +
            "#d**e#" +
            "#dffe#" +
            "#ghhi#" +
            "# jj #" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Agatka"), /* group */ 1,
            /* width and height */ 7, 7,
            "..     " +
            ".      " +
            "#####--" +
            "#**aab-" +
            "#*ccde#" +
            "#fgh  #" +
            "#######" },

        /* Translators: puzzle name */
        {   N_("Success"), /* group */ 1,
            /* width and height */ 9, 6,
            "#######  " +
            "#**bbc#  " +
            "#defgh#  " +
            "#ijkgh-  " +
            "#llk  #  " +
            "#######.." },

        /* Translators: puzzle name */
        {   N_("Bone"), /* group */ 1,
            /* width and height */ 6, 9,
            "######" +
            "#abc*#" +
            "# dd*#" +
            "# ee*#" +
            "# fgh#" +
            "##-###" +
            "     ." +
            "     ." +
            "     ." },

        /* Translators: puzzle name */
        {   N_("Fortune"), /* group */ 1,
            /* width and height */ 7, 10,
            "     .." +
            "     . " +
            "####-. " +
            "#ab  - " +
            "#ccd # " +
            "#ccd # " +
            "#**ee# " +
            "#*fgh# " +
            "#*iih# " +
            "###### " },

        /* Translators: puzzle name */
        {   N_("Fool"), /* group */ 1,
            /* width and height */ 10, 6,
            "  ########" +
            "  -aabc  #" +
            "  #aabdef#" +
            "  #ijggef#" +
            "  #klhh**#" +
            "..########" },

        /* Translators: puzzle name */
        {   N_("Solomon"), /* group */ 1,
            /* width and height */ 7, 9,
            " .     " +
            "..     " +
            "#--####" +
            "#  aab#" +
            "# cdfb#" +
            "#hcefg#" +
            "#hijk*#" +
            "#hll**#" +
            "#######" },

        /* Translators: puzzle name */
        {   N_("Cleopatra"), /* group */ 1,
            /* width and height */ 6, 8,
            "######" +
            "#abcd#" +
            "#**ee#" +
            "#f*g #" +
            "#fh i-" +
            "####--" +
            "    .." +
            "     ." },

        /* Translators: puzzle name */
        {   N_("Shark"), /* group */ 1,
            /* width and height */ 11, 8,
            "########   " +
            "#nrr s #   " +
            "#n*op q#   " +
            "#***jml#   " +
            "#hhijkl#   " +
            "#ffcddg-   " +
            "#abcdde- . " +
            "########..." },

        /* Translators: puzzle name */
        {   N_("Rome"), /* group */ 1,
            /* width and height */ 8, 8,
            "########" +
            "#abcc**#" +
            "#ddeef*#" +
            "#ddghfi#" +
            "#   jki#" +
            "#--#####" +
            " ..     " +
            "  .     " },

        /* Translators: puzzle name */
        {   N_("Pennant Puzzle"), /* group */ 1,
            /* width and height */ 6, 9,
            "######" +
            "#**aa#" +
            "#**bb#" +
            "#de  #" +
            "#fghh#" +
            "#fgii#" +
            "#--###" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Ithaca"), /* group */ 2,
            /* width and height */ 19, 19,
            ".aaaaaaaaaaaaaaaaab" +
            "..  cddeffffffffffb" +
            " .. cddeffffffffffb" +
            "  . cddeffffffffffb" +
            "ggg-############hhb" +
            "ggg-  ABCDEFFGH#hhb" +
            "ggg-       FFIJ#hhb" +
            "ggg#       KLMJ#hhb" +
            "ggg#NNNNOOOPQMJ#hhb" +
            "ggg#NNNNOOOP*RS#hhb" +
            "ggg#TTTTTUVW**X#hhb" +
            "ggg#YZ12222W3**#hhb" +
            "ggg#YZ12222W34*#iib" +
            "jjj#YZ155555367#klb" +
            "jjj#############mmb" +
            "jjjnooooooooooppppb" +
            "jjjqooooooooooppppb" +
            "       rrrssssppppb" +
            "ttttttuvvvvvvvwwwwx" },

        /* Translators: puzzle name */
        {   N_("Pelopones"), /* group */ 2,
            /* width and height */ 9, 8,
            "#########" +
            "#abbb***#" +
            "#abbb*c*#" +
            "#adeefgg#" +
            "#  eefhh#" +
            "#... ihh#" +
            "#. . ihh#" +
            "#########" },

        /* Translators: puzzle name */
        {   N_("Transeuropa"), /* group */ 2,
            /* width and height */ 15, 8,
            "    ###########" +
            "    -AAAAABBCC#" +
            "    -   DEFGHI#" +
            "    #   DEFGJI#" +
            "    #   KEFGLI#" +
            "    #   KEFG*I#" +
            "  . #   MM****#" +
            "....###########" },

        /* Translators: puzzle name */
        {   N_("Lodzianka"), /* group */ 2,
            /* width and height */ 9, 7,
            "#########" +
            "#**abbcc#" +
            "#**abbdd#" +
            "#eefgh  #" +
            "#iiijk..#" +
            "#iiijk..#" +
            "#########" },

        /* Translators: puzzle name */
        {   N_("Polonaise"), /* group */ 2,
            /* width and height */ 7, 7,
            "#######" +
            "#aab**#" +
            "#aabc*#" +
            "#defgg#" +
            "#..fhh#" +
            "# .ihh#" +
            "#######" },

        /* Translators: puzzle name */
        {   N_("Baltic Sea"), /* group */ 2,
            /* width and height */ 6, 8,
            "######" +
            "#.abc#" +
            "#.dec#" +
            "#fggc#" +
            "#fhhi#" +
            "#fjk*#" +
            "#flk*#" +
            "######" },

        /* Translators: puzzle name */
        {   N_("American Pie"), /* group */ 2,
            /* width and height */ 10, 12,
            "##########" +
            "#a*bcdefg#" +
            "#**bhhhhg#" +
            "#*iijjkkg#" +
            "#liimnoop#" +
            "#qiirrr  #" +
            "#qstuvv  #" +
            "#qwwxvv  #" +
            "######--##" +
            "         ." +
            "        .." +
            "        . " },

        /* Translators: puzzle name */
        {   N_("Traffic Jam"), /* group */ 2,
            /* width and height */ 10, 7,
            "########  " +
            "#** ffi#  " +
            "#** fgh#  " +
            "#aacehh#  " +
            "#bbdjlm-  " +
            "#bddklm-.." +
            "########.." },

        /* Translators: puzzle name */
        {   N_("Sunshine"), /* group */ 2,
            /* width and height */ 17, 22,
            "       ...       " +
            "      .. ..      " +
            "      .   .      " +
            "      .. ..      " +
            "       ...       " +
            "######-----######" +
            "#hh0iilltmmpp;qq#" +
            "#hh,iill mmpp:qq#" +
            "#2y{45v s w89x/z#" +
            "#jj6kkaa nnoo<rr#" +
            "#jj7kkaaunnoo>rr#" +
            "#33333TTJWW11111#" +
            "#33333TTJWW11111#" +
            "#33333GG HH11111#" +
            "#33333YYIgg11111#" +
            "#33333YYIgg11111#" +
            "#ddFeeA***BffOZZ#" +
            "#ddFee** **ffOZZ#" +
            "#MMKQQ*   *PPS^^#" +
            "#VVLXX** **bbRcc#" +
            "#VVLXXD***EbbRcc#" +
            "#################" }
    };

    private const GLib.ActionEntry win_actions [] =
    {
        { "show-scores",    show_scores         },
        { "prev-pack",      prev_pack_cb        },
        { "next-pack",      next_pack_cb        },
        { "prev-puzzle",    prev_puzzle_cb      },
        { "next-puzzle",    next_puzzle_cb      },
        { "start-game",     start_puzzle_cb     },
        { "unfullscreen",   unfullscreen        },

        { "help",           help_cb             },
        { "about",          about_cb            }
    };

    private static string normalize_map_name (string name)
    {
        return name.down ().replace (" ", "-");
    }

    class construct
    {
        score_categories = new Gee.ArrayList<Games.Scores.Category> ();
        for (uint8 i = 0; i < levels.length; i++)
        {
            score_categories.add (new Games.Scores.Category (normalize_map_name (levels [i].name),
                                                             _(levels [i].name)));
        }
    }

    private Games.Scores.Category? category_request (string key)
    {
        for (uint8 i = 0; i < levels.length; i++)
        {
            if (key == normalize_map_name (levels [i].name))
                return score_categories [i];
        }
        return null;
    }

    private void parse_old_score (string line, out Games.Scores.Score? score, out Games.Scores.Category? category)
    {
        score = null;
        category = null;

        string [] tokens = line.split (" ");
        if (tokens.length != 3)
            return;

        int64 date = Games.Scores.HistoryFileImporter.parse_date (tokens [0]);
        if (date == 0)
            return;

        int level = int.parse (tokens [1]);
        if (level == 0 && tokens [1] != "0")
            return;
        if (level < 0 || level > score_categories.size)
            return;

        int moves = int.parse (tokens [2]);
        if (moves <= 0)
            return;

        score = new Games.Scores.Score (moves, date);
        category = score_categories [level];
    }

    construct
    {
        CssProvider css_provider = new CssProvider ();
        css_provider.load_from_resource ("/org/gnome/Klotski/ui/klotski.css");
        Gdk.Screen? gdk_screen = Gdk.Screen.get_default ();
        if (gdk_screen != null) // else..?
            StyleContext.add_provider_for_screen ((!) gdk_screen, css_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        settings = new GLib.Settings ("org.gnome.Klotski");
        set_default_size (settings.get_int ("window-width"), settings.get_int ("window-height"));
        if (settings.get_boolean ("window-is-maximized"))
            maximize ();

        init_keyboard ();
        manage_high_contrast ();

        add_action_entries (win_actions, this);
        lookup_non_nullable_action ("prev-pack",    out prev_pack);
        lookup_non_nullable_action ("next-pack",    out next_pack);
        lookup_non_nullable_action ("prev-puzzle",  out prev_puzzle);
        lookup_non_nullable_action ("next-puzzle",  out next_puzzle);
        lookup_non_nullable_action ("start-game",   out start_game);

        scores_context = new Games.Scores.Context.with_importer_and_icon_name (
            "gnome-klotski",
             /* Translators: in the Scores dialog, label indicating for which puzzle the best scores are displayed */
             _("Puzzle"),
             this,
             category_request,
             Games.Scores.Style.POINTS_LESS_IS_BETTER,
             new Games.Scores.HistoryFileImporter (parse_old_score),
             "org.gnome.Klotski");

        // name, active, puzzle number (or -1), sensitive=false CSS hack
        liststore_huarong   = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));
        liststore_challenge = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));
        liststore_skill     = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));

        puzzles_items = new TreeIter [levels.length];
        for (uint8 i = 0; i < levels.length; i++)
        {
            switch (levels [i].group)
            {
                case 0:
                    liststore_huarong.append (out puzzles_items [i]);
                    liststore_huarong.set (puzzles_items [i],
                                           0, _(levels [i].name),
                                           1, false,
                                           2, i,
                                           3, false);
                    break;
                case 1:
                    liststore_challenge.append (out puzzles_items [i]);
                    liststore_challenge.set (puzzles_items [i],
                                             0, _(levels [i].name),
                                             1, false,
                                             2, i,
                                             3, false);
                    break;
                case 2:
                    liststore_skill.append (out puzzles_items [i]);
                    liststore_skill.set (puzzles_items [i],
                                         0, _(levels [i].name),
                                         1, false,
                                         2, i,
                                         3, false);
                    break;
                default: assert_not_reached ();
            }
        }

        treeview_huarong.set_model (liststore_huarong);
        treeview_challenge.set_model (liststore_challenge);
        treeview_skill.set_model (liststore_skill);

        treeview_huarong.row_activated.connect (level_huarong_cb);
        treeview_challenge.row_activated.connect (level_challenge_cb);
        treeview_skill.row_activated.connect (level_skill_cb);

        view = new PuzzleView ();
        view.halign = Align.FILL;
        view.can_focus = true;
        view.show ();
        view.hexpand = true;
        view.vexpand = true;
        main_grid.add (view);

        load_solved_state ();       // TODO use GSettings, or the history…

        current_level = settings.get_int (KEY_LEVEL).clamp (0, levels.length - 1);
        puzzles_popover.show.connect (() => update_popover (true));
        update_popover (true);      // or “Start Over” logically complains

        start_puzzle ();
    }

    private void lookup_non_nullable_action (string name, out SimpleAction action)
    {
        GLib.Action? nullable_action = lookup_action (name);
        if (nullable_action == null)
            assert_not_reached ();
        action = (SimpleAction) (!) nullable_action;
    }

    /*\
    * * Window management callbacks
    \*/

    [GtkCallback]
    private void on_size_allocate (Allocation allocation)
    {
        update_window_state ();
    }

    [GtkCallback]
    private bool on_window_state_event (Gdk.EventWindowState event)
    {
        if ((event.changed_mask & Gdk.WindowState.MAXIMIZED) != 0)
            window_is_maximized = (event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0;

        /* fullscreen: saved as maximized */
        bool window_was_fullscreen = window_is_fullscreen;
        if ((event.changed_mask & Gdk.WindowState.FULLSCREEN) != 0)
            window_is_fullscreen = (event.new_window_state & Gdk.WindowState.FULLSCREEN) != 0;
        if (window_was_fullscreen && !window_is_fullscreen)
            on_unfullscreen ();
        else if (!window_was_fullscreen && window_is_fullscreen)
            on_fullscreen ();

        /* tiled: not saved, but should not change saved window size */
        Gdk.WindowState tiled_state = Gdk.WindowState.TILED
                                    | Gdk.WindowState.TOP_TILED
                                    | Gdk.WindowState.BOTTOM_TILED
                                    | Gdk.WindowState.LEFT_TILED
                                    | Gdk.WindowState.RIGHT_TILED;
        if ((event.changed_mask & tiled_state) != 0)
            window_is_tiled = (event.new_window_state & tiled_state) != 0;

        return false;
    }
    protected void on_fullscreen ()
    {
        unfullscreen_button.show ();
    }
    protected void on_unfullscreen ()
    {
        unfullscreen_button.hide ();
    }

    [GtkCallback]
    private void on_destroy ()
    {
        settings.set_int (KEY_LEVEL, current_level);
        save_window_state ();
    }

    /*\
    * * manage window state
    \*/

    private void update_window_state () // called on size-allocate
    {
        if (window_is_maximized || window_is_tiled || window_is_fullscreen)
            return;
        int? _window_width = null;
        int? _window_height = null;
        get_size (out _window_width, out _window_height);
        if (_window_width == null || _window_height == null)
            return;
        window_width = (!) _window_width;
        window_height = (!) _window_height;
    }

    private void save_window_state ()   // called on destroy
    {
        settings.delay ();
        settings.set_int ("window-width", window_width);
        settings.set_int ("window-height", window_height);
        settings.set_boolean ("window-is-maximized", window_is_maximized || window_is_fullscreen);
        settings.apply ();
    }

    /*\
    * * Popover’s buttons callbacks
    \*/

    private void prev_pack_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        current_pack--;
        update_popover (false);
    }

    private void next_pack_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        current_pack++;
        update_popover (false);
    }

    private void prev_puzzle_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        if (levels [current_level].group == current_pack)
            current_level--;
        else
        {
            int tmp_level;
            for (tmp_level = levels.length - 1; tmp_level >= 0; tmp_level--)
                if (levels [tmp_level].group == current_pack)
                    break;
            current_level = tmp_level;
        }
        update_popover (true);
        start_puzzle ();
    }

    private void next_puzzle_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        if (levels [current_level].group == current_pack)
            current_level++;
        else
        {
            int tmp_level;
            for (tmp_level = 0; tmp_level < levels.length; tmp_level++)
                if (levels [tmp_level].group == current_pack)
                    break;
            current_level = tmp_level;
        }
        update_popover (true);
        start_puzzle ();
    }

    private void start_puzzle_cb ()
    {
        TreeView tree = ((TreeView) (((ScrolledWindow) (stack_puzzles.get_children ().nth_data (current_pack))).get_child ()));
        TreeModel? model = tree.get_model ();
        if (model == null)
            assert_not_reached ();
        TreeIter iter;

        if (tree.get_selection ().get_selected (out model, out iter))
            start_puzzle_from_iter ((Gtk.ListStore) model, iter);
        else
            start_puzzle ();
        puzzles_popover.hide ();
    }

    /*\
    * * Update popover
    \*/

    private void update_popover (bool make_current)
    {
        int current_level_pack;
        TreeIter iter = puzzles_items [current_level];
        if (liststore_huarong.iter_is_valid (iter))          // "slow"
            current_level_pack = 0;
        else if (liststore_challenge.iter_is_valid (iter))   // same here
            current_level_pack = 1;
        else
            current_level_pack = 2;

        if (make_current)
            current_pack = current_level_pack;

        /* select or not a level */
        TreeSelection selection = ((TreeView) (((ScrolledWindow) (stack_puzzles.get_children ().nth_data (current_pack))).get_child ())).get_selection ();
        if (current_pack == current_level_pack)
            selection.select_iter (iter);
        else
            selection.unselect_all ();

        update_buttons_state ();

        /* update stacks */
        stack_packs.set_visible_child (stack_packs.get_children ().nth_data (current_pack));
        stack_puzzles.set_visible_child (stack_puzzles.get_children ().nth_data (current_pack));
    }

    private void update_buttons_state ()
    {
        prev_pack.set_enabled (current_pack > 0);
        next_pack.set_enabled (current_pack < 2);

        prev_puzzle.set_enabled (current_level > 0);
        next_puzzle.set_enabled (current_level < levels.length - 1);
    }

    /*\
    * * Selecting puzzle by the treeview
    \*/

    private void level_huarong_cb (TreePath path, TreeViewColumn column)
    {
        level_cb (liststore_huarong, path, column);
    }
    private void level_challenge_cb (TreePath path, TreeViewColumn column)
    {
        level_cb (liststore_challenge, path, column);
    }
    private void level_skill_cb (TreePath path, TreeViewColumn column)
    {
        level_cb (liststore_skill, path, column);
    }
    private void level_cb (Gtk.ListStore liststore, TreePath path, TreeViewColumn column)
    {
        TreeIter iter;

        liststore.get_iter (out iter, path);
        start_puzzle_from_iter (liststore, iter);
    }

    /*\
    * * Creating and starting game
    \*/

    private void start_puzzle_from_iter (Gtk.ListStore model, TreeIter iter)
    {
        Value val;
        model.get_value (iter, 2, out val);

        int requested_level = (int) val;
        if (requested_level < 0)
            return;

        current_level = requested_level;
        update_buttons_state ();
        start_puzzle ();
    }

    private void start_puzzle ()
    {
        headerbar.set_title (_(levels [current_level].name));
        if (puzzle_init_done)
            SignalHandler.disconnect_by_func (puzzle, null, this);
        puzzle = new Puzzle (levels [current_level].width, levels [current_level].height, levels [current_level].data);
        puzzle_init_done = true;
        puzzle.moved.connect (puzzle_moved_cb);     // TODO disconnect previous puzzle?
        view.puzzle = puzzle;

        update_moves_label ();
        game_menubutton.active = false;
        start_game.set_enabled (false);
        game_menubutton.sensitive = false;
    }

    private void puzzle_moved_cb ()
    {
        update_moves_label ();
    }

    private void update_moves_label ()
    {
        start_game.set_enabled (true);
        game_menubutton.sensitive = true;
        /* Translators: headerbar subtitle; the %d is replaced by the number of moves already done in the current game */
        game_menubutton.set_label (puzzle.moves.to_string ());
        if (puzzle.game_over ())
        {
            /* Translators: headerbar title, when the puzzle is solved */
            headerbar.set_title (_("Level completed."));    // FIXME remove the dot
            game_score ();
        }
    }

    /*\
    * * Scores
    \*/

    private void game_score ()
    {
        /* Level is complete */
        string key = get_level_key (current_level);
        KeyFile keyfile = new KeyFile ();
        string filename = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "levels");  // filename:~/.local/share/gnome-klotski/levels

        try
        {
            keyfile.load_from_file (filename, KeyFileFlags.NONE);
        }
        catch (Error e)
        {
        }

        keyfile.set_boolean (key, "solved", true);

        try
        {
            FileUtils.set_contents (filename, keyfile.to_data ());
        }
        catch (Error e)
        {
        }

        puzzle_solved (puzzles_items [current_level], true);

        scores_context.add_score.begin (puzzle.moves,
                                        score_categories [current_level],
                                        null,
                                        (object, result) => {
                try
                {
                    scores_context.add_score.end (result);
                }
                catch (Error e)
                {
                    warning ("Failed to add score: %s", e.message);
                }
            });
    }

    private void show_scores ()
    {
        scores_context.run_dialog ();
    }

    private string get_level_key (int level_number)
    {
        /* Calculate the CRC of the level data */
        uint32 result = 0xFFFFFFFFu;
        string data = levels [level_number].data;
        for (uint i = 0; data [i] != '\0'; i++)
        {
            char octet = data [i];
            for (uint8 j = 0; j < 8; j++)
            {
                if (((octet >> 7) ^ (result >> 31)) != 0)
                    result = (result << 1) ^ 0x04c11db7;
                else
                    result = (result << 1);
                result &= 0xFFFFFFFFu;
                octet <<= 1;
            }
        }

        return "%08X".printf (~result);
    }

    private void load_solved_state ()
    {
        KeyFile keyfile = new KeyFile ();
        string filename = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "levels");
        try
        {
            keyfile.load_from_file (filename, KeyFileFlags.NONE);
        }
        catch (Error e)
        {
        }

        for (uint8 i = 0; i < levels.length; i++)
        {
            string key = get_level_key (i);
            bool is_solved = false;
            try
            {
                is_solved = keyfile.get_boolean (key, "solved");
            }
            catch (Error e)
            {
            }

            puzzle_solved (puzzles_items [i], is_solved);
        }
    }

    private void puzzle_solved (TreeIter iter, bool solved)
    {
        if (liststore_huarong.iter_is_valid (iter))          // "slow"
            liststore_huarong.set (iter, 1, solved);
        else if (liststore_challenge.iter_is_valid (iter))   // same here
            liststore_challenge.set (iter, 1, solved);
        else
            liststore_skill.set (iter, 1, solved);
    }

    /*\
    * * manage high-constrast
    \*/

    private StyleContext window_style_context;

    private inline void manage_high_contrast ()
    {
        Gtk.Settings? nullable_gtk_settings = Gtk.Settings.get_default ();
        if (nullable_gtk_settings == null)
            return;

        window_style_context = get_style_context ();

        Gtk.Settings gtk_settings = (!) nullable_gtk_settings;
        gtk_settings.notify ["gtk-theme-name"].connect (update_highcontrast_state);
        _update_highcontrast_state (gtk_settings.gtk_theme_name);
    }

    private void update_highcontrast_state (Object gtk_settings, ParamSpec unused)
    {
        _update_highcontrast_state (((Gtk.Settings) gtk_settings).gtk_theme_name);
    }

    private bool highcontrast_state = false;
    private void _update_highcontrast_state (string theme_name)
    {
        bool highcontrast_new_state = "HighContrast" in theme_name;
        if (highcontrast_new_state == highcontrast_state)
            return;
        highcontrast_state = highcontrast_new_state;

        if (highcontrast_new_state)
            window_style_context.add_class ("hc-theme");
        else
            window_style_context.remove_class ("hc-theme");
    }

    /*\
    * * keyboard shortcuts
    \*/

    private EventControllerKey key_controller;          // for keeping in memory

    private inline void init_keyboard ()
    {
        key_controller = new EventControllerKey (this);
        key_controller.propagation_phase = PropagationPhase.CAPTURE;
        key_controller.key_pressed.connect (on_key_pressed);
    }

    private inline bool on_key_pressed (EventControllerKey _key_controller, uint keyval, uint keycode, Gdk.ModifierType state)
    {
        string name = (!) (Gdk.keyval_name (keyval) ?? "");

        if (name == "F1")   // Gtk handles badly having F1 or Shift-F1 as action shortcut while using Ctrl-F1 automatically
        {
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0)
                return false;   // help overlay
            if ((state & Gdk.ModifierType.SHIFT_MASK) == 0)
            {
                help_cb ();
                return true;
            }
            else
            {
                about_cb ();
                return true;
            }
         // return false;
        }
        if (name == "F10")  // Gtk handles badly having F10 and Ctrl-F10 as actions shortcuts
        {
            if (state == 0)
            {
                main_menubutton.active = !main_menubutton.active;
                return true;
            }
            if (game_menubutton.sensitive
             && (state & Gdk.ModifierType.CONTROL_MASK) != 0)
            {
                game_menubutton.active = !game_menubutton.active;
                return true;
            }
            return false;
        }
        return false;
    }

    /*\
    * * help and about
    \*/

    private inline void help_cb ()
    {
        try
        {
            show_uri_on_window (this, "help:gnome-klotski", get_current_event_time ());
        }
        catch (Error e)
        {
            warning ("Failed to show help: %s", e.message);
        }
    }

    private inline void about_cb ()
    {
        string [] authors = {
        /* Translators: text crediting an author, in the about dialog */
            _("Lars Rydlinge (original author)"),


        /* Translators: text crediting an author, in the about dialog */
            _("Robert Ancell (port to vala)"),


        /* Translators: text crediting an author, in the about dialog */
            _("John Cheetham (port to vala)")
        };

        /* Translators: text crediting a documenter, in the about dialog */
        string [] documenters = { _("Andrew Sobala") };

        show_about_dialog (this,
                           /* Translators: name of the program, seen in the About dialog */
                           "program-name", Klotski.PROGRAM_NAME,

                           "version", VERSION,
                           /* Translators: small description of the game, seen in the About dialog */
                           "comments", _("Sliding block puzzles"),

                           "copyright",
                             /* Translators: text crediting a maintainer, seen in the About dialog */
                             _("Copyright \xc2\xa9 1999-2008 – Lars Rydlinge") + "\n"+


                             /* Translators: text crediting a maintainer, seen in the About dialog; the %u are replaced with the years of start and end */
                             _("Copyright \xc2\xa9 %u-%u – Michael Catanzaro").printf (2014, 2016) + "\n"+


                             /* Translators: text crediting a maintainer, seen in the About dialog; the %u are replaced with the years of start and end */
                             _("Copyright \xc2\xa9 %u-%u – Arnaud Bonatti").printf (2015, 2020),
                           "license-type", License.GPL_3_0, // means "GNU General Public License, version 3.0 or later"
                           "authors", authors,
                           "documenters", documenters,
                           "logo-icon-name", "org.gnome.Klotski",
                           /* Translators: about dialog text; this string should be replaced by a text crediting yourselves and your translation team, or should be left empty. Do not translate literally! */
                           "translator-credits", _("translator-credits"),
                           "website", "https://wiki.gnome.org/Apps/Klotski");
    }
}
