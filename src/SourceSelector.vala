//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

public class Maya.View.SourceSelector : Gtk.Popover {
    private Gee.HashMap<string, SourceItem?> src_map;

    private Gtk.Stack stack;
    private SourceDialog src_dialog = null;

    private Gtk.Grid main_grid;
    private Gtk.Grid calendar_grid;
    private int calendar_index = 0;
    private Gtk.ScrolledWindow scroll;
    private E.SourceRegistry registry;

    public SourceSelector () {
        modal = false;
        stack = new Gtk.Stack ();

        calendar_grid = new Gtk.Grid ();
        calendar_grid.row_spacing = 12;
        calendar_grid.margin_start = calendar_grid.margin_end = 6;

        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        scroll.expand = true;
        scroll.add (calendar_grid);

        main_grid = new Gtk.Grid ();
        main_grid.row_spacing = 6;
        main_grid.margin_top = 6;

        src_map = new Gee.HashMap<string, SourceItem?>();

        try {
            registry = new E.SourceRegistry.sync (null);
            var sources = registry.list_sources (E.SOURCE_EXTENSION_CALENDAR);
            foreach (var src in sources) {
                add_source_to_view (src);
            }

            registry.source_removed.connect (source_removed);
            registry.source_added.connect (add_source_to_view);
            registry.source_disabled.connect (source_disabled);
            registry.source_enabled.connect (add_source_to_view);
        } catch (GLib.Error error) {
            critical (error.message);
        }

        var add_calendar_button = new Gtk.Button.with_label (_("Add New Calendar…"));
        add_calendar_button.hexpand = true;
        add_calendar_button.margin_start = add_calendar_button.margin_end = 6;
        add_calendar_button.clicked.connect (create_source);

        var add_calendar_grid = new Gtk.Grid ();
        add_calendar_grid.attach (add_calendar_button, 0, 0, 1, 1);

        main_grid.attach (scroll, 0, 0, 1, 1);
        main_grid.attach (add_calendar_grid, 0, 2, 1, 1);

        stack.add_named (main_grid, "main");
        stack.margin_bottom = 5;

        this.add (stack);
        main_grid.show_all ();
    }

    private void source_removed (E.Source source) {
        var source_item = src_map.get (source.dup_uid ());
        source_item.hide ();
        src_map.unset (source.dup_uid ());
        source_item.destroy ();
    }

    private void source_disabled (E.Source source) {
        var source_item = src_map.get (source.dup_uid ());
        source_item.source_has_changed ();
    }

    private void create_source () {
        if (src_dialog == null) {
            src_dialog = new SourceDialog ();
            src_dialog.go_back.connect (() => {switch_to_main ();});
            stack.add_named (src_dialog, "source");
        }

        src_dialog.set_source (null);
        switch_to_source ();
    }

    private void add_source_to_view (E.Source source) {
        if (source.enabled == false)
            return;

        if (src_map.has_key (source.dup_uid ()))
            return;

        var source_item = new SourceItem (source);
        source_item.edit_request.connect (edit_source);
        source_item.remove_request.connect (remove_source);

        calendar_grid.attach (source_item, 0, calendar_index, 1, 1);
        int minimum_height;
        int natural_height;
        calendar_index++;
        calendar_grid.show_all ();
        calendar_grid.get_preferred_height (out minimum_height, out natural_height);
        if (natural_height > 150) {
            scroll.set_size_request (-1, 150);
        } else {
            scroll.set_size_request (-1, natural_height);
        }

        src_map.set (source.dup_uid (), source_item);
    }

    private void remove_source (E.Source source) {
        Model.CalendarModel.get_default ().delete_calendar (source);
        var source_item = src_map.get (source.dup_uid ());
        source_item.show_calendar_removed ();
    }

    private void edit_source (E.Source source) {
        if (src_dialog == null) {
            src_dialog = new SourceDialog ();
            src_dialog.go_back.connect (() => {switch_to_main ();});
            stack.add_named (src_dialog, "source");
        }

        src_dialog.set_source (source);
        switch_to_source ();
    }

    private void switch_to_main () {
        main_grid.no_show_all = false;
        main_grid.show ();
        stack.set_visible_child_full ("main", Gtk.StackTransitionType.SLIDE_RIGHT);
        src_dialog.hide ();
        src_dialog.no_show_all = true;
    }

    private void switch_to_source () {
        src_dialog.no_show_all = false;
        src_dialog.show ();
        stack.set_visible_child_full ("source", Gtk.StackTransitionType.SLIDE_LEFT);
        main_grid.hide ();
        main_grid.no_show_all = true;
    }
}