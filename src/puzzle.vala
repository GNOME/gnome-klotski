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

private class Puzzle : Object
{
    /*
      1   2   4

      8   *   16

      32  64  128
    */
    private const int [] image_map =
    {
        0,    0, // 🞍

        64,   1, // ╻
        66,   2, // ┃
        2,    3, // ╹

        16,   4, // ╺
        24,   5, // ━
        8,    6, // ╸

        208,  7, // ▗
        248,  8, // ▄
        104,  9, // ▖

        214, 10, // ▐
        255, 11, // █
        107, 12, // ▌

        22,  13, // ▝
        31,  14, // ▀
        11,  15, // ▘

        18,  16, // ┗
        10,  17, // ┛
        80,  18, // ┏
        72,  19, // ┓

        /* Follows in the file */
        // small dot for creating the target
        // empty
        // dots for marking the red donkey, but not at scale? fixed thing?
        // square for exit door
        // black square (?)
        // ??

        /* Misc */
        56,   5,
        152,  5,
        70,   2,
        67,   2,
        194,  2,
        98,   2,
        9,    6,
        20,   4,
        144,  4,
        3,    3,
        40,   6,
        25,   5,
        28,   5,
        96,   1,
        19,  16,
        201, 19,
        146, 16,
        198,  2,
        84,  18,
        46,  17,
        112, 18,
        6,    3,
        184,  5,
        192,  1,
        147, 16,
        73,  19,
        42,  17,
        200, 19,
        99,   2,
        116, 18,
        29,   5,
        14,  17,
        26,  25,
        224,  1,

        -1,  -1
    };

    [CCode (notify = false)] internal uint8 width   { internal get; private set; }
    [CCode (notify = false)] internal uint8 height  { internal get; private set; }

    // Type `char []' can not be used for a GLib.Object property
    internal char [] map;
    internal char [] move_map;
    internal char [] orig_map;
    internal char [] lastmove_map;
    internal char [] undomove_map;

    [CCode (notify = false)] internal int moves     { internal get; internal set; default = 0; }

    internal signal void changed ();
    internal signal void moved ();

    internal Puzzle (uint8 width, uint8 height, string? data)
    {
        this.width = width;
        this.height = height;
        map = new char[(width + 2) * (height + 2)];
        move_map = map;
        undomove_map = map;
        if (data != null)
        {
            uint16 i = 0;
            for (uint8 y = 0; y < height; y++)
            {
                for (uint8 x = 0; x < width; x++)
                {
                    set_piece_id (map, x, y, data [i]);
                    i++;
                }
            }
        }
        orig_map = map;
        lastmove_map = map;
    }

    internal char get_piece_id (char [] src, uint8 x, uint8 y)
    {
        return src [(uint16) x + 1 + ((uint16) y + 1) * ((uint16) width + 2)];
    }

    private void set_piece_id (char [] src, uint8 x, uint8 y, char id)
    {
        src [(uint16) x + 1 + ((uint16) y + 1) * ((uint16) width + 2)] = id;
    }

    internal int get_piece_nr (uint8 x, uint8 y)
    {
        x++;
        y++;

        var c = map [(uint16) x + (uint16) y * ((uint16) width + 2)];
        if (c == '-')
            return 23;
        if (c == ' ')
            return 21;
        if (c == '.')
            return 20;

        uint8 nr = 0;
        if (map [((uint16) x - 1) + ((uint16) y - 1) * ((uint16) width + 2)] == c)
            nr += 1;
        if (map [((uint16) x    ) + ((uint16) y - 1) * ((uint16) width + 2)] == c)
            nr += 2;
        if (map [((uint16) x + 1) + ((uint16) y - 1) * ((uint16) width + 2)] == c)
            nr += 4;
        if (map [((uint16) x - 1) + ((uint16) y    ) * ((uint16) width + 2)] == c)
            nr += 8;
        if (map [((uint16) x + 1) + ((uint16) y    ) * ((uint16) width + 2)] == c)
            nr += 16;
        if (map [((uint16) x - 1) + ((uint16) y + 1) * ((uint16) width + 2)] == c)
            nr += 32;
        if (map [((uint16) x    ) + ((uint16) y + 1) * ((uint16) width + 2)] == c)
            nr += 64;
        if (map [((uint16) x + 1) + ((uint16) y + 1) * ((uint16) width + 2)] == c)
            nr += 128;

        uint8 i = 0;
        while (nr != image_map [i] && image_map [i] != -1)
            i += 2;

        return image_map [i + 1];
    }

    internal bool game_over ()
    {
        bool over = true;
        for (uint8 y = 0; y < height; y++)
            for (uint8 x = 0; x < width; x++)
                if (get_piece_id (map, x, y) == '*' && get_piece_id (orig_map, x, y) != '.')
                    over = false;   // TODO return false?
        return over;
    }

    internal bool mapcmp (char [] m1, char [] m2)
    {
        for (uint8 y = 0; y < height; y++)
            for (uint8 x = 0; x < width; x++)
                if (get_piece_id (m1, x, y) != get_piece_id (m2, x, y))
                    return true;
        return false;
    }

    internal bool movable (int id)
    {
        if (id == '#' || id == '.' || id == ' ' || id == '-')
            return false;
        return true;
    }

    internal bool move_piece (char id, uint8 x1, uint8 y1, uint8 x2, uint8 y2)
    {
        var return_value = false;

        if (!movable (id))
            return false;

        if (get_piece_id (map, x2, y2) == id)
            return_value = true;

        if (!((y1 == y2 && ((int) x1 - (int) x2).abs () == 1) || (x1 == x2 && ((int) y1 - (int) y2).abs () == 1)))
            return false;

        if (((int) y1 - (int) y2).abs () == 1)
        {
            if (y1 < y2)
            {
                if (check_valid_move (id, 0, 1))
                    return do_move_piece (id, 0, 1);
            }
            else if (y1 > y2)
            {
                if (check_valid_move (id, 0, -1))
                    return do_move_piece (id, 0, -1);
            }
        }

        if (((int) x1 - (int) x2).abs () == 1)
        {
            if (x1 < x2)
            {
                if (check_valid_move (id, 1, 0))
                    return do_move_piece (id, 1, 0);
            }
            else if (x1 > x2)
            {
                if (check_valid_move (id, -1, 0))
                    return do_move_piece (id, -1, 0);
            }
        }

        return return_value;
    }

    private bool check_valid_move (int id, int dx, int dy)
    {
        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                if (get_piece_id (map, x, y) == id)
                {
                    var z = get_piece_id (map, x + dx, y + dy);
                    if (!(z == ' ' || z == '.' || z == id || (id == '*' && z == '-')))
                        return false;
                }
            }
        }

        return true;
    }

    private bool do_move_piece (char id, int dx, int dy)
    {
        var tmpmap = map;

        /* Move pieces */
        for (var y = 0; y < height; y++)
            for (var x = 0; x < width; x++)
                if (get_piece_id (tmpmap, x, y) == id)
                    set_piece_id (tmpmap, x, y, ' ');

        for (var y = 0; y < height; y++)
            for (var x = 0; x < width; x++)
                if (get_piece_id (map, x, y) == id)
                    set_piece_id (tmpmap, (x + dx), (y + dy), id);

        /* Preserve some from original map */
        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                if (get_piece_id (tmpmap, x, y) == ' ' && get_piece_id (orig_map, x, y) == '.')
                    set_piece_id (tmpmap, x, y, '.');
                if (get_piece_id (tmpmap, x, y) == ' ' && get_piece_id (orig_map, x, y) == '-')
                    set_piece_id (tmpmap, x, y, '-');
            }
        }

#if 0
        /* Paint changes */
        for (var y = 0; y < height; y++)
            for (var x = 0; x < width; x++)
                if (get_piece_id (map, x, y) != get_piece_id (tmpmap, x, y) || get_piece_id (tmpmap, x, y) == id)
                    ; // FIXME: Just redraw the required space
#endif
        changed ();

        map = tmpmap;

        return true;
    }
}
