/* Puzzle Info */
private struct LevelInfo
{
    string name;
    int group;
    int width;
    int height;
    string data;
}

public class Klotski : Gtk.Application
{
    private Settings settings;
    private const int MINWIDTH = 250;
    private const int MINHEIGHT = 250;
    private const int SPACE_PADDING = 5;

    private const string KEY_LEVEL = "level";

    /* Main window */
    private Gtk.Window window;
    private int window_width;
    private int window_height;
    private bool is_fullscreen;
    private bool is_maximized;

    private PuzzleView view;

    private Gtk.ToolButton fullscreen_button;

    private Gtk.Label messagewidget;
    private Gtk.Label moves_label;

    private Gtk.ActionGroup gaction_group;

    private Puzzle puzzle;

    private int current_level = -1;

    private History history;

    /* The "puzzle name" remarks provide context for translation. */
    private Gtk.SizeGroup groups[3];
    private Gtk.Image[] level_image;
    private Gtk.ToggleAction[] level_action;
    public const LevelInfo level[] =
    {
      /* puzzle name */
      {N_("Only 18 Steps"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#m**n#" +
       "#cdef#" +
       "#ghij#" +
       "#k  l#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Daisy"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdef#" +
       "#zghi#" +
       "#j  k#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Violet"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdef#" +
       "#cghi#" +
       "#j  k#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Poppy"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdde#" +
       "#fghi#" +
       "#j  k#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Pansy"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdef#" +
       "#cghf#" +
       "#i  j#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Snowdrop"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdde#" +
       "#cfgh#" +
       "#i  j#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name - sometimes called "Le'Ane Rouge" */
      {N_("Red Donkey"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdde#" +
       "#cfge#" +
       "#h  i#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Trail"), 0,
       6, 9,
       "######" +
       "#a**c#" +
       "#a**c#" +
       "#eddg#" +
       "#hffj#" +
       "# ii #" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Ambush"), 0,
       6, 9,
       "######" +
       "#a**c#" +
       "#d**e#" +
       "#dffe#" +
       "#ghhi#" +
       "# jj #" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Agatka"), 1,
       7, 7,
       "..     " +
       ".      " +
       "#####--" +
       "#**aab-" +
       "#*ccde#" +
       "#fgh  #" +
       "#######"},

      /* puzzle name */
      {N_("Success"), 1,
       9, 6,
       "#######  " +
       "#**bbc#  " +
       "#defgh#  " +
       "#ijkgh-  " +
       "#llk  #  " +
       "#######.."},

      /* puzzle name */
      {N_("Bone"), 1,
       6, 9,
       "######" +
       "#abc*#" +
       "# dd*#" +
       "# ee*#" +
       "# fgh#" +
       "##-###" +
       "     ." +
       "     ." +
       "     ."},

      /* puzzle name */
      {N_("Fortune"), 1,
       7, 10,
       "     .." +
       "     . " +
       "####-. " +
       "#ab  - " +
       "#ccd # " +
       "#ccd # " +
       "#**ee# " +
       "#*fgh# " +
       "#*iih# " +
       "###### "},

      /* puzzle name */
      {N_("Fool"), 1,
       10, 6,
       "  ########" +
       "  -aabc  #" +
       "  #aabdef#" +
       "  #ijggef#" +
       "  #klhh**#" +
       "..########"},

      /* puzzle name */
      {N_("Solomon"), 1,
       7, 9,
       " .     " +
       "..     " +
       "#--####" +
       "#  aab#" +
       "# cdfb#" +
       "#hcefg#" +
       "#hijk*#" +
       "#hll**#" +
       "#######"},

      /* puzzle name */
      {N_("Cleopatra"), 1,
       6, 8,
       "######" +
       "#abcd#" +
       "#**ee#" +
       "#f*g #" +
       "#fh i-" +
       "####--" +
       "    .." +
       "     ."},

      /* puzzle name */
      {N_("Shark"), 1,
       11, 8,
       "########   " +
       "#nrr s #   " +
       "#n*op q#   " +
       "#***jml#   " +
       "#hhijkl#   " +
       "#ffcddg-   " +
       "#abcdde- . " +
       "########..."},

      /* puzzle name */
      {N_("Rome"), 1,
       8, 8,
       "########" +
       "#abcc**#" +
       "#ddeef*#" +
       "#ddghfi#" +
       "#   jki#" +
       "#--#####" +
       " ..     " +
       "  .     "},

      /* puzzle name */
      {N_("Pennant Puzzle"), 1,
       6, 9,
       "######" +
       "#**aa#" +
       "#**bb#" +
       "#de  #" +
       "#fghh#" +
       "#fgii#" +
       "#--###" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Ithaca"), 2,
       19, 19,
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
       "ttttttuvvvvvvvwwwwx"},

      /* puzzle name */
      {N_("Pelopones"), 2,
       9, 8,
       "#########" +
       "#abbb***#" +
       "#abbb*c*#" +
       "#adeefgg#" +
       "#  eefhh#" +
       "#... ihh#" +
       "#. . ihh#" +
       "#########"},

      /* puzzle name */
      {N_("Transeuropa"), 2,
       15, 8,
       "    ###########" +
       "    -AAAAABBCC#" +
       "    -   DEFGHI#" +
       "    #   DEFGJI#" +
       "    #   KEFGLI#" +
       "    #   KEFG*I#" +
       "  . #   MM****#" +
       "....###########"},

      /* puzzle name */
      {N_("Lodzianka"), 2,
       9, 7,
       "#########" +
       "#**abbcc#" +
       "#**abbdd#" +
       "#eefgh  #" +
       "#iiijk..#" +
       "#iiijk..#" +
       "#########"},

      /* puzzle name */
      {N_("Polonaise"), 2,
       7, 7,
       "#######" +
       "#aab**#" +
       "#aabc*#" +
       "#defgg#" +
       "#..fhh#" +
       "# .ihh#" +
       "#######"},

      /* puzzle name */
      {N_("Baltic Sea"), 2,
       6, 8,
       "######" +
       "#.abc#" +
       "#.dec#" +
       "#fggc#" +
       "#fhhi#" +
       "#fjk*#" +
       "#flk*#" +
       "######"},

      /* puzzle name */
      {N_("American Pie"), 2,
       10, 12,
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
       "        . "},

      /* puzzle name */
      {N_("Traffic Jam"), 2,
       10, 7,
       "########  " +
       "#** ffi#  " +
       "#** fgh#  " +
       "#aacehh#  " +
       "#bbdjlm-  " +
       "#bddklm-.." +
       "########.."},

      /* puzzle name */
      {N_("Sunshine"), 2,
       17, 22,
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
       "#################"}
    };

    const string[] pack_uipath =
    {
        "/ui/MainMenu/GameMenu/HuaRongTrail",
        "/ui/MainMenu/GameMenu/ChallengePack",
        "/ui/MainMenu/GameMenu/SkillPack"
    };

    private const GLib.ActionEntry[] action_entries =
    {
        { "new-game",             restart_level_cb  },
        { "fullscreen",           fullscreen_cb     },
        { "scores",               scores_cb         },
        { "help",                 help_cb           },
        { "about",                about_cb          },
        { "quit",                 quit_cb           }
    };

    const Gtk.ActionEntry[] entries =
    {
        {"GameMenu", null, N_("_Game")},
        /* set of puzzles */
        {"HuaRongTrail", null, N_("HuaRong Trail")},
        /* set of puzzles */
        {"ChallengePack", null, N_("Challenge Pack")},
        /* set of puzzles */
        {"SkillPack", null, N_("Skill Pack")},
        {"RestartPuzzle", Gtk.Stock.REFRESH, N_("_Restart Puzzle"), "<control>R", null, restart_level_cb},
        {"NextPuzzle", Gtk.Stock.GO_FORWARD, N_("Next Puzzle"), "Page_Down", null, next_level_cb},
        {"PrevPuzzle", Gtk.Stock.GO_BACK, N_("Previous Puzzle"), "Page_Up", null, prev_level_cb}
    };

    const string ui_description =
      "<ui>" +
      "  <menubar name='MainMenu'>" +
      "    <menu action='GameMenu'>" +
      "      <menuitem action='RestartPuzzle'/>" +
      "      <menuitem action='NextPuzzle'/>" +
      "      <menuitem action='PrevPuzzle'/>" +
      "      <separator/>" +
      "      <menu action='HuaRongTrail'/>" +
      "      <menu action='ChallengePack'/>" +
      "      <menu action='SkillPack'/>" +
      "    </menu>" +
      "  </menubar>" +
      "</ui>";

    public Klotski ()
    {
        Object (application_id: "org.gnome.klotski", flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void startup ()
    {
        base.startup ();

        Environment.set_application_name (_("Klotski"));

        settings = new Settings ("org.gnome.klotski");

        Gtk.Window.set_default_icon_name ("gnome-klotski");

        add_action_entries (action_entries, this);
        add_accelerator ("F11", "app.fullscreen", null);

        level_action = new Gtk.ToggleAction[level.length];
        level_image = new Gtk.Image[level.length];

        string histfile = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "history");

        history = new History (histfile);
        history.load ();

        window = new Gtk.ApplicationWindow (this);
        window.set_title (_("Klotski"));
        window.configure_event.connect (window_configure_event_cb);
        window.window_state_event.connect (window_state_event_cb);
        int ww = settings.get_int ("window-width");
        int wh = settings.get_int ("window-height");
        if (ww < MINWIDTH)
            ww = MINWIDTH;
        if (wh < MINHEIGHT)
           wh = MINHEIGHT;

        window.set_default_size (ww, wh);
        if (settings.get_boolean ("window-is-fullscreen"))
            window.fullscreen ();
        else if (settings.get_boolean ("window-is-maximized"))
            window.maximize ();

        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        window.add (vbox);
        vbox.show ();

        /* Create the menu */

        var builder_str =
               "<interface>" +
                /* string for menu */
               """
               <menu id='app-menu'>
                  <section>
                   <item>
                      <attribute name='label' translatable='yes'>_New Game</attribute>
                      <attribute name='action'>app.new-game</attribute>
                      <attribute name='accel'>&lt;Primary&gt;n</attribute>
                   </item>
                   <item>
                      <attribute name='label' translatable='yes'>_Scores</attribute>
                      <attribute name='action'>app.scores</attribute>
                   </item>
                  </section>
                  <section>
                   <item>
                      <attribute name='label' translatable='yes'>_Help</attribute>
                      <attribute name='action'>app.help</attribute>
                      <attribute name='accel'>F1</attribute>
                   </item>
                   <item>
                      <attribute name='label' translatable='yes'>_About</attribute>
                      <attribute name='action'>app.about</attribute>
                   </item>
                  </section>
                  <section>
                   <item>
                      <attribute name='label' translatable='yes'>_Quit</attribute>
                      <attribute name='action'>app.quit</attribute>
                      <attribute name='accel'>&lt;Primary&gt;q</attribute>
                   </item>
                  </section>
                </menu>
               </interface>
               """;

        Gtk.Builder builder = new Gtk.Builder ();

        try
        {
            builder.add_from_string (builder_str, -1);
        }
        catch (GLib.Error e)
        {
            stderr.printf ("%s\n", "Error in gnome-klotski.vala function startup() - builder.add_from_string failed");
            GLib.error(e.message);
        }

        set_app_menu (builder.get_object ("app-menu") as MenuModel);

        gaction_group = new Gtk.ActionGroup ("MenuActions");
        gaction_group.set_translation_domain (GETTEXT_PACKAGE);
        gaction_group.add_actions (entries, this);

        var ui_manager = new Gtk.UIManager ();
        ui_manager.insert_action_group (gaction_group, 0);
        try
        {
            ui_manager.add_ui_from_string (ui_description, -1);
        }
        catch (Error e)
        {
        }
        add_puzzle_menu (ui_manager);


        window.add_accel_group (ui_manager.get_accel_group ());

        var menubar = ui_manager.get_widget ("/MainMenu");
        vbox.pack_start (menubar, false, false, 0);

        var status_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        status_box.show ();

        /* show the puzzle name and number of moves */
        messagewidget = new Gtk.Label ("");
        messagewidget.show ();
        status_box.pack_start (messagewidget, false, false, 0);

        moves_label = new Gtk.Label ("");
        moves_label.show ();

        status_box.pack_start (moves_label, false, false, 0);

        var toolbar = new Gtk.Toolbar ();
        toolbar.show ();
        toolbar.show_arrow = false;
        toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);

        var new_game_button = new Gtk.ToolButton (null, N_("_New"));
        new_game_button.icon_name = "document-new";
        new_game_button.use_underline = true;
        new_game_button.action_name = "app.new-game";
        new_game_button.is_important = true;
        new_game_button.show ();
        toolbar.insert (new_game_button, -1);

        fullscreen_button = new Gtk.ToolButton (null, _("_Fullscreen"));
        fullscreen_button.icon_name = "view-fullscreen";
        fullscreen_button.use_underline = true;
        fullscreen_button.action_name = "app.fullscreen";
        fullscreen_button.show ();
        toolbar.insert (fullscreen_button, -1);

        var status_alignment = new Gtk.Alignment (1.0f, 0.5f, 0.0f, 0.0f);
        status_alignment.add (status_box);
        status_alignment.show ();

        var status_item = new Gtk.ToolItem ();
        status_item.set_expand (true);
        status_item.add (status_alignment);
        status_item.show ();

        toolbar.insert (status_item, -1);

        vbox.pack_start (toolbar, false, false, 0);

        view = new PuzzleView ();
        view.show ();
        vbox.pack_start (view, true, true, 0);

        vbox.pack_start (new Gtk.HSeparator (), false, false, 0);

        load_solved_state ();

        var startup_level = settings.get_int (KEY_LEVEL);
        new_game (startup_level);
    }

    private bool window_configure_event_cb (Gdk.EventConfigure event)
    {
        if (!is_maximized && !is_fullscreen)
        {
            window_width = event.width;
            window_height = event.height;
        }

        return false;
    }

    private bool window_state_event_cb (Gdk.EventWindowState event)
    {
        if ((event.changed_mask & Gdk.WindowState.MAXIMIZED) != 0)
            is_maximized = (event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0;
        if ((event.changed_mask & Gdk.WindowState.FULLSCREEN) != 0)
        {
            is_fullscreen = (event.new_window_state & Gdk.WindowState.FULLSCREEN) != 0;
            if (is_fullscreen)
            {
                fullscreen_button.label = _("_Leave Fullscreen");
                fullscreen_button.icon_name = "view-restore";
            }
            else
            {
                fullscreen_button.label = _("_Fullscreen");
                fullscreen_button.icon_name = "view-fullscreen";
            }
        }
        return false;
    }

    private void scores_cb ()
    {
        show_scores (null, false);
    }

    private void game_score ()
    {
        /* Level is complete */
        var key = get_level_key (current_level);
        var keyfile = new KeyFile ();
        var filename = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "levels");  // filename:~/.local/share/gnome-klotski/levels

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

        level_image[current_level].set_from_stock (Gtk.Stock.YES, Gtk.IconSize.MENU);

        var date = new DateTime.now_local ();
        var entry = new HistoryEntry (date, current_level, puzzle.moves);
        history.add (entry);
        history.save ();

        if (show_scores (entry, true) == Gtk.ResponseType.CLOSE)
            window.destroy ();
        else
            new_game (current_level);

    }

    private int show_scores (HistoryEntry? selected_entry = null, bool show_quit = false)
    {
        var dialog = new ScoreDialog (history, selected_entry, show_quit, gaction_group);
        dialog.modal = true;
        dialog.transient_for = window;

        var result = dialog.run ();
        dialog.destroy ();

        return result;
     }


    /* Add puzzles to the game menu. */
    private void add_puzzle_menu (Gtk.UIManager ui_manager)
    {
        unowned SList group = null;
        Gtk.RadioAction? top_action = null;
        for (var i = level.length - 1; i >= 0; i--)
        {
            var label = gaction_group.translate_string (level[i].name);

            var action = new Gtk.RadioAction (level[i].name, "", null, null, i);
            top_action = action;

            action.set_group (group);
            group = action.get_group ();

            gaction_group.add_action (action);

            ui_manager.add_ui (ui_manager.new_merge_id (),
                               pack_uipath[level[i].group],
                               level[i].name, level[i].name,
                               Gtk.UIManagerItemType.MENUITEM, true);

            /* Unfortunately Gtk.UIManager only supports labels for items, so remove the label it creates and
             * replace it with our own widget */
            Gtk.Bin item = (Gtk.Bin) ui_manager.get_widget (pack_uipath[level[i].group] + "/" + level[i].name);

            /* Create a label and image for the menu item */
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var labelw = new Gtk.Label (label);
            labelw.set_alignment (0.0f, 0.5f);
            var image = new Gtk.Image ();
            box.pack_start (labelw, true, true, 0);
            box.pack_start (image, false, true, 0);

            /* Keep all elements the same size */
            if (groups[level[i].group] == null)
                groups[level[i].group] = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
            groups[level[i].group].add_widget (box);

            /* Replace the label with the new one */
            item.remove (item.get_child ());
            item.add (box);
            box.show_all ();

            level_image[i] = image;
            level_action[i] = action;
        }

        top_action.changed.connect (level_cb);
    }

    private string get_level_key (int level_number)
    {
        /* Calculate the CRC of the level data */
        uint32 result = 0xFFFFFFFFu;
        var data = level[level_number].data;
        for (var i = 0; data[i] != '\0'; i++)
        {
            var octet = data[i];
            for (var j = 0; j < 8; j++)
            {
                if (((octet >> 7) ^ (result >> 31)) != 0)
                    result = (result << 1) ^ 0x04c11db7;
                else
                    result = (result << 1);
                result &= 0xFFFFFFFF;
                octet <<= 1;
            }
        }

        return "%08X".printf (~result);
    }

    private void load_solved_state ()
    {
        var keyfile = new KeyFile ();
        var filename = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "levels");
        try
        {
            keyfile.load_from_file (filename, KeyFileFlags.NONE);
        }
        catch (Error e)
        {
        }

        for (var i = 0; i < level.length; i++)
        {
            var key = get_level_key (i);
            var value = false;
            try
            {
                value = keyfile.get_boolean (key, "solved");
            }
            catch (Error e)
            {
            }
            if (value)
                level_image[i].set_from_stock (Gtk.Stock.YES, Gtk.IconSize.MENU);
        }
    }

    private void update_menu_state ()
    {
        /* Puzzle Radio Action */
        level_action[current_level].active = true;

        /* Next Puzzle Sensitivity */
        var action = gaction_group.get_action ("NextPuzzle");
        action.sensitive = current_level < level.length - 1;

        /* Previous Puzzle Sensitivity */
        action = gaction_group.get_action ("PrevPuzzle");
        action.sensitive = current_level > 0;

        update_moves_label ();
    }

    private void new_game (int requested_level)
    {
        current_level = requested_level.clamp (0, level.length - 1);

        settings.set_int (KEY_LEVEL, current_level);

        messagewidget.set_text (N_("Puzzle: ") + _(level[current_level].name));
        puzzle = new Puzzle (level[current_level].width, level[current_level].height, level[current_level].data);
        puzzle.moved.connect (puzzle_moved_cb);
        view.puzzle = puzzle;
        update_menu_state ();
    }

    private void puzzle_moved_cb ()
    {
        update_moves_label ();
    }

    private void update_moves_label ()
    {
        moves_label.set_text (_("Moves: %d").printf (puzzle.moves));
        if (puzzle.game_over ())
        {
            messagewidget.set_text (_("Level completed."));
            game_score ();
        }
    }

    private void quit_cb ()
    {
        window.destroy ();
    }

    private void level_cb (Gtk.Action action, Gtk.RadioAction current)
    {
        int requested_level = current.get_current_value ();
        if (requested_level != current_level)
            new_game (requested_level);
    }

    private void restart_level_cb ()
    {
        new_game (current_level);
    }

    private void next_level_cb ()
    {
        new_game (current_level + 1);
    }

    private void prev_level_cb ()
    {
        new_game (current_level - 1);
    }

    private void help_cb ()
    {
        try
        {
            Gtk.show_uri (window.get_screen (), "help:gnotski", Gtk.get_current_event_time ());
        }
        catch (Error e)
        {
            warning ("Failed to show help: %s", e.message);
        }
    }

    protected override void shutdown ()
    {
        base.shutdown ();

        /* Save window state */
        settings.set_int ("window-width", window_width);
        settings.set_int ("window-height", window_height);
        settings.set_boolean ("window-is-maximized", is_maximized);
        settings.set_boolean ("window-is-fullscreen", is_fullscreen);
    }

    protected override void activate ()
    {
        window.present ();
    }

    private void fullscreen_cb ()
    {
        if (is_fullscreen)
        {
            window.unfullscreen ();
        }
        else
        {
            window.fullscreen ();
        }
    }

    private void about_cb ()
    {
        const string authors[] = { "Lars Rydlinge (original author)", "Robert Ancell (port to vala)", "John Cheetham (port to vala)", null };
        const string documenters[] = { "Andrew Sobala", null };
        var license = "Klotski is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.\n\nKlotski is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with Klotski; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA";

        Gtk.show_about_dialog (window,
                               "program-name", _("Klotski"),
                               "version", VERSION,
                               "comments", _("Sliding Block Puzzles\n\nKlotski is a part of GNOME Games."),
                               "copyright",
                               "Copyright \xc2\xa9 1999-2008 Lars Rydlinge",
                               "license", license,
                               "wrap-license", true,
                               "authors", authors,
                               "documenters", documenters,
                               "translator-credits", _("translator-credits"),
                               "logo-icon-name", "gnome-klotski",
                               "website", "http://www.gnome.org/projects/gnome-games",
                               "website-label", _("GNOME Games web site"),
                               null);

    }

    public static int main (string[] args)
    {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        var context = new OptionContext ("");
        context.set_translation_domain (GETTEXT_PACKAGE);
        context.add_group (Gtk.get_option_group (true));

        try
        {
            context.parse (ref args);
        }
        catch (Error e)
        {
            stderr.printf ("%s\n", e.message);
            Posix.exit (Posix.EXIT_FAILURE);
        }

        var app = new Klotski ();
        return app.run (args);
    }
}

public class ScoreDialog : Gtk.Dialog
{
    private History history;
    private HistoryEntry? selected_entry = null;
    private Gtk.ListStore level_model;
    private Gtk.ListStore score_model;
    private Gtk.ComboBox level_combo;
    private Gtk.ActionGroup action_group;

    public ScoreDialog (History history, HistoryEntry? selected_entry = null, bool show_quit = false, Gtk.ActionGroup action_group)
    {
        this.history = history;
        history.entry_added.connect (entry_added_cb);
        this.selected_entry = selected_entry;
        this.action_group = action_group;

        if (show_quit)
        {
            add_button (Gtk.Stock.QUIT, Gtk.ResponseType.CLOSE);
            add_button (_("New Game"), Gtk.ResponseType.OK);
        }
        else
            add_button (Gtk.Stock.OK, Gtk.ResponseType.DELETE_EVENT);
        set_size_request (200, 300);

        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        vbox.border_width = 6;
        vbox.show ();
        get_content_area ().pack_start (vbox, true, true, 0);

        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        hbox.show ();
        vbox.pack_start (hbox, false, false, 0);

        var label = new Gtk.Label (_("Puzzle:"));
        label.show ();
        hbox.pack_start (label, false, false, 0);

        level_model = new Gtk.ListStore (2, typeof (string), typeof (int));  // puzzle name, level

        level_combo = new Gtk.ComboBox ();
        level_combo.changed.connect (level_changed_cb);
        level_combo.model = level_model;
        var renderer = new Gtk.CellRendererText ();
        level_combo.pack_start (renderer, true);
        level_combo.add_attribute (renderer, "text", 0);
        level_combo.show ();
        hbox.pack_start (level_combo, true, true, 0);

        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.shadow_type = Gtk.ShadowType.ETCHED_IN;
        scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scroll.show ();
        vbox.pack_start (scroll, true, true, 0);

        score_model = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (int));

        var scores = new Gtk.TreeView ();
        renderer = new Gtk.CellRendererText ();
        scores.insert_column_with_attributes (-1, _("Date"), renderer, "text", 0, "weight", 2);
        renderer = new Gtk.CellRendererText ();
        renderer.xalign = 1.0f;
        scores.insert_column_with_attributes (-1, _("Moves"), renderer, "text", 1, "weight", 2);
        scores.model = score_model;
        scores.show ();
        scroll.add (scores);

        foreach (var entry in history.entries)
            entry_added_cb (entry);
    }

    public void set_level (uint level)
    {
        score_model.clear ();

        var entries = history.entries.copy ();
        entries.sort (compare_entries);

        foreach (var entry in entries)
        {
            if (entry.level != level)
                continue;

            var date_label = entry.date.format ("%d/%m/%Y");

            var moves_label = "%u".printf (entry.moves);

            int weight = Pango.Weight.NORMAL;
            if (entry == selected_entry)
                weight = Pango.Weight.BOLD;

            Gtk.TreeIter iter;
            score_model.append (out iter);
            score_model.set (iter, 0, date_label, 1, moves_label, 2, weight);
        }
    }

    private static int compare_entries (HistoryEntry a, HistoryEntry b)
    {
        if (a.level != b.level)
            return (int) a.level - (int) b.level;
        if (a.moves != b.moves)
            return (int) a.moves - (int) b.moves;
        return a.date.compare (b.date);
    }

    private void level_changed_cb (Gtk.ComboBox combo)
    {
        Gtk.TreeIter iter;
        if (!combo.get_active_iter (out iter))
            return;

        int level;
        combo.model.get (iter, 1, out level);
        set_level ((uint) level);
    }

    private void entry_added_cb (HistoryEntry entry)
    {
        /* Ignore if already have an entry for this */
        Gtk.TreeIter iter;
        var have_level_entry = false;
        if (level_model.get_iter_first (out iter))
        {
            do
            {
                uint level;
                level_model.get (iter, 1, out level);
                if (level == entry.level)
                {
                    have_level_entry = true;
                    break;
                }
            } while (level_model.iter_next (ref iter));
        }

        if (!have_level_entry)
        {
            var label = action_group.translate_string (Klotski.level[entry.level].name);
            level_model.append (out iter);
            level_model.set (iter, 0, label, 1, entry.level, -1);

            /* Select this entry if don't have any */
            if (level_combo.get_active () == -1)
                level_combo.set_active_iter (iter);

            /* Select this entry if the same category as the selected one */
            if (selected_entry != null && entry.level == selected_entry.level)
                level_combo.set_active_iter (iter);

        }
    }
}
