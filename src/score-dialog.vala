/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

using Gtk;

[GtkTemplate (ui = "/org/gnome/klotski/ui/scores.ui")]
public class ScoreDialog : Dialog
{
    private History history;
    private HistoryEntry? selected_entry = null;

    [GtkChild]
    private Gtk.ListStore levels_liststore;
    [GtkChild]
    private Gtk.ListStore scores_liststore;
    [GtkChild]
    private ComboBox level_combo;
    [GtkChild]
    private TreeView scores_tree;

    public ScoreDialog (History history, HistoryEntry? selected_entry = null)
    {
        bool use_header = Gtk.Settings.get_default ().gtk_dialogs_use_header;
        Object (use_header_bar: use_header ? 1 : 0);
        if (!use_header)
            add_button (_("_OK"), ResponseType.DELETE_EVENT);

        this.history = history;
        history.entry_added.connect (entry_added_cb);
        this.selected_entry = selected_entry;

        level_combo.changed.connect (level_changed_cb);

        foreach (var entry in history.entries)
            entry_added_cb (entry);
    }

    /*\
    * * Combo reaction
    \*/

    private void level_changed_cb (ComboBox combo)
    {
        TreeIter iter;
        if (!combo.get_active_iter (out iter))
            return;

        int level;
        levels_liststore.get (iter, 1, out level);

/*      set_level ((uint) level);
    }

    public void set_level (uint level)      // TODO why??
    {
        TreeIter iter;
*/
        scores_liststore.clear ();

        var entries = history.entries.copy ();
        entries.sort (compare_entries);

        foreach (var entry in entries)
        {
            if (entry.level != level)
                continue;

            var date_label = entry.date.format ("%d/%m/%Y");    // TODO
            var moves_label = "%u".printf (entry.moves);

            scores_liststore.append (out iter);

            if (entry != selected_entry)
            {
                scores_liststore.set (iter,
                                      0, date_label,
                                      1, moves_label,
                                      2, Pango.Weight.NORMAL);
            }
            else
            {
                scores_liststore.set (iter,
                                      0, date_label,
                                      1, moves_label,
                                      2, Pango.Weight.BOLD);
                var piter = iter;
                if (scores_liststore.iter_previous (ref piter))
                {
                    var ppiter = piter;
                    if (scores_liststore.iter_previous (ref ppiter))
                        piter = ppiter;
                }
                else
                    piter = iter;
                scores_tree.scroll_to_cell (scores_liststore.get_path (piter), null, false, 0, 0);
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

    /*\
    * * Combo and TreeView population
    \*/

    private void entry_added_cb (HistoryEntry entry)
    {
        /* Ignore if already have an entry for this */
        TreeIter iter;
        var have_level_entry = false;
        if (levels_liststore.get_iter_first (out iter))
        {
            do
            {
                uint level;
                levels_liststore.get (iter, 1, out level);
                if (level == entry.level)
                {
                    have_level_entry = true;
                    break;
                }
            } while (levels_liststore.iter_next (ref iter));
        }

        if (!have_level_entry)
        {
            var label = _(Klotski.level[entry.level].name);
            levels_liststore.append (out iter);
            levels_liststore.set (iter,
                                  0, label,
                                  1, entry.level);

            /* Select this entry if don't have any */
            if (level_combo.get_active () == -1)
                level_combo.set_active_iter (iter);

            /* Select this entry if the same category as the selected one */
            if (selected_entry != null && entry.level == selected_entry.level)
                level_combo.set_active_iter (iter);
        }
    }
}
