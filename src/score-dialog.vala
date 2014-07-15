/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

 public class ScoreDialog : Gtk.Dialog
{
    private History history;
    private HistoryEntry? selected_entry = null;
    private Gtk.ListStore level_model;
    private Gtk.ListStore score_model;
    private Gtk.ComboBox level_combo;
    private Gtk.TreeView scores;

    public ScoreDialog (History history, HistoryEntry? selected_entry = null, bool show_close = false)
    {
        this.history = history;
        history.entry_added.connect (entry_added_cb);
        this.selected_entry = selected_entry;

        if (show_close)
        {
            add_button (_("_Close"), Gtk.ResponseType.CLOSE);
            add_button (_("New Game"), Gtk.ResponseType.OK);
        }
        else
            add_button (_("_OK"), Gtk.ResponseType.DELETE_EVENT);
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

        scores = new Gtk.TreeView ();
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

            if (entry == selected_entry)
            {
                var piter = iter;
                if (score_model.iter_previous (ref piter))
                {
                    var ppiter = piter;
                    if (score_model.iter_previous (ref ppiter))
                        piter = ppiter;
                }
                else
                    piter = iter;
                scores.scroll_to_cell (score_model.get_path (piter), null, false, 0, 0);
            }
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
            var label = _(Klotski.level[entry.level].name);
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
