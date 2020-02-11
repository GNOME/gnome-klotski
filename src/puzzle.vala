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

        8   *  16

        32 64 128
    */
    private const uint8 [] image_map =
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
        // 20 = small dot for creating the target; direct return from get_piece_nr()
        // 21 = empty; direct return from get_piece_nr()
        // 22 = pyramid; its center (only!) is used for making the dots on the red donkey; used from puzzle-view.vala
        // 23 = square for exit door, direct return from get_piece_nr()
        //      black square (?)
        // 25 = left-top-right linked square; used in Shark and Transeuropa (1/3)

        /* left and right and */
        25,   5, // top-left
        28,   5, // top-right
        56,   5, // bottom-left
        152,  5, // bottom-right
        184,  5, // bottom-left and bottom-right; used in Sunshine and Pelopones
        29,   5, // top-left and top-right; used in Sunshine
        // nine more doable

        /* top and bottom and */
        67,   2, // top-left
        70,   2, // top-right
        98,   2, // bottom-left
        194,  2, // bottom-right
        99,   2, // top-left and bottom-left; used in Sunshine
        198,  2, // top-right and bottom-right; used in Sunshine
        // nine more doable

        /* left and */
        9,    6, // top-left
        40,   6, // bottom-left
        // one more doable

        /* right and */
        20,   4, // top-right
        144,  4, // bottom-right
        // one more doable

        /* top and */
        3,    3, // top-left
        6,    3, // top-right
        // one more doable

        /* bottom and */
        96,   1, // bottom-left
        192,  1, // bottom-right
        224,  1, // bottom-left and bottom-right; used in Shark and Transeuropa (2/3)

        /* top and left and */
        14,  17, // top-right
        42,  17, // bottom-left
        46,  17, // top-right and bottom-left

        /* top and right and */
        19,  16, // top-left
        146, 16, // bottom-right
        147, 16, // top-left and bottom-right

        /* bottom and left and */
        73,  19, // top-left
        200, 19, // bottom-right
        201, 19, // top-left and bottom-right

        /* bottom and right and */
        84,  18, // top-right
        112, 18, // bottom-left
        116, 18, // top-right and bottom-left

        /* top and left and right */
        26,  25  // used in Shark and Transeuropa (3/3)
        // many more (180?) of this kind and others doable
    };
    private uint8 image_map_length = 54;

    [CCode (notify = false)] public uint8   width       { internal get; protected construct; }
    [CCode (notify = false)] public uint8   height      { internal get; protected construct; }
    [CCode (notify = false)] public string  initial_map { private  get; protected construct; }

    // Type `char []' can not be used for a GLib.Object property
    internal char [] map;
    internal char [] move_map;
    internal char [] orig_map;      // TODO unduplicate with initial_map
    internal char [] lastmove_map;
    internal char [] undomove_map;

    [CCode (notify = false)] internal uint16 moves  { internal get; internal set; default = 0; }

    internal signal void changed ();
    internal signal void moved ();

    internal Puzzle (uint8 width, uint8 height, string initial_map)
    {
        Object (width: width, height: height, initial_map: initial_map);
    }

    construct
    {
        map = new char [(width + 2) * (height + 2)];
        move_map = map;
        undomove_map = map;

        uint16 i = 0;
        for (uint8 y = 0; y < height; y++)
            for (uint8 x = 0; x < width; x++)
            {
                set_piece_id (map, x, y, initial_map [i]);
                i++;
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

        char c = map [(uint16) x + (uint16) y * ((uint16) width + 2)];
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

        for (uint8 i = 0; i < image_map_length * 2; i += 2)
        {
            if (nr == image_map [i])
                return image_map [i + 1];
        }
        assert_not_reached ();
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

    internal static inline bool is_static_tile (char id)
    {
        if (id == '#' || id == '.' || id == ' ' || id == '-')
            return true;
        else
            return false;
    }

    internal bool move_piece (char id, uint8 x1, uint8 y1, uint8 x2, uint8 y2)
    {
        bool return_value = false;

        if (is_static_tile (id))
            return false;

        if (get_piece_id (map, x2, y2) == id)
            return_value = true;

        if (!((y1 == y2 && ((int) x1 - (int) x2).abs () == 1) || (x1 == x2 && ((int) y1 - (int) y2).abs () == 1)))
            return false;

        if (((int) y1 - (int) y2).abs () == 1)
        {
            if (y1 < y2)
            {
                if (check_valid_move     (id,  0,  1))
                    return do_move_piece (id,  0,  1);
            }
            else if (y1 > y2)
            {
                if (check_valid_move     (id,  0, -1))
                    return do_move_piece (id,  0, -1);
            }
        }

        if (((int) x1 - (int) x2).abs () == 1)
        {
            if (x1 < x2)
            {
                if (check_valid_move     (id,  1,  0))
                    return do_move_piece (id,  1,  0);
            }
            else if (x1 > x2)
            {
                if (check_valid_move     (id, -1,  0))
                    return do_move_piece (id, -1,  0);
            }
        }

        return return_value;
    }

    internal bool can_be_moved (char id)
    {
        if (is_static_tile (id))
            return false;

        return check_valid_move (id,  0,  1)
            || check_valid_move (id,  0, -1)
            || check_valid_move (id,  1,  0)
            || check_valid_move (id, -1,  0);
    }

    private bool check_valid_move (char id, int8 dx, int8 dy)
    {
        for (int8 y = 0; y < height; y++)
        {
            for (int8 x = 0; x < width; x++)
            {
                if (get_piece_id (map, x, y) == id)
                {
                    char z = get_piece_id (map, x + dx, y + dy);
                    if (!(z == ' ' || z == '.' || z == id || (id == '*' && z == '-')))
                        return false;
                }
            }
        }

        return true;
    }

    private bool do_move_piece (char id, int8 dx, int8 dy)
    {
        char [] tmpmap = map;

        /* Move pieces */
        for (uint8 y = 0; y < height; y++)
            for (uint8 x = 0; x < width; x++)
                if (get_piece_id (tmpmap, x, y) == id)
                    set_piece_id (tmpmap, x, y, ' ');

        for (int8 y = 0; y < height; y++)
            for (int8 x = 0; x < width; x++)
                if (get_piece_id (map, x, y) == id)
                    set_piece_id (tmpmap, x + dx, y + dy, id);

        /* Preserve some from original map */
        for (uint8 y = 0; y < height; y++)
        {
            for (uint8 x = 0; x < width; x++)
            {
                if (get_piece_id (tmpmap, x, y) == ' ' && get_piece_id (orig_map, x, y) == '.')
                    set_piece_id (tmpmap, x, y, '.');
                if (get_piece_id (tmpmap, x, y) == ' ' && get_piece_id (orig_map, x, y) == '-')
                    set_piece_id (tmpmap, x, y, '-');
            }
        }

#if 0
        /* Paint changes */
        for (uint8 y = 0; y < height; y++)
            for (uint8 x = 0; x < width; x++)
                if (get_piece_id (map, x, y) != get_piece_id (tmpmap, x, y) || get_piece_id (tmpmap, x, y) == id)
                    ; // FIXME: Just redraw the required space
#endif
        changed ();

        map = tmpmap;

        return true;
    }
}
