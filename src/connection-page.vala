/* connection-page.vala
 *
 * Copyright (C) 2026 DriverDing
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

class Valash.ConnectionPage : Gtk.Box {
    private Gtk.ScrolledWindow scrolled_window;
    private GLib.ListStore store;
    private Gtk.SingleSelection selection;
    private Gtk.ColumnView view;

    construct {
        scrolled_window = new Gtk.ScrolledWindow ();
        store = new GLib.ListStore (typeof (ConnectionData));
        selection = new Gtk.SingleSelection (store) { autoselect = false };
        view = new Gtk.ColumnView (selection) { hexpand = true };

        append_column (_("Host"), (data) => {
            return "%s:%s".printf (data.metadata.host, data.metadata.destination_port);
        });
        append_column (_("Chains"), (data) => {
            return string.joinv (" <- ", data.chains);
        });
        append_column (_("Download"), (data) => {
            return format_value (data.download);
        }, 100);
        append_column (_("Upload"), (data) => {
            return format_value (data.upload);
        }, 100);

        scrolled_window.set_child (view);
        this.append (scrolled_window);
    }

    delegate string Formatter (ConnectionData data);

    private void append_column (string title, Formatter formatter, int? fixed_width = null) {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((item) => {
            var list_item = (Gtk.ListItem) item;
            var inscription = new Gtk.Inscription (null);
            // inscription.add_css_class ("inscription");
            list_item.set_child (inscription);
        });
        factory.bind.connect ((factory, item) => {
            var list_item = (Gtk.ListItem) item;
            var inscription = (Gtk.Inscription) list_item.get_child ();
            var data = (ConnectionData) list_item.get_item ();
            inscription.text = formatter (data);
        });
        var column = new Gtk.ColumnViewColumn (title, factory);
        if (fixed_width == null) {
            column.expand = true;
        } else {
            column.set_fixed_width (fixed_width);
        }
        view.append_column (column);
    }

    public void on_connections_received (ConnectionsData data) {
        refresh (data);
    }

    private void refresh (ConnectionsData data) {
        // Mark All Connections
        Gee.HashSet<string> to_append = new Gee.HashSet<string> ();
        foreach (string id in data.connections.keys) {
            to_append.add (id);
        }

        // Remove Broke Connections, Splice Existing Connections
        for (int i = (int) store.get_n_items () - 1; i >= 0; i -= 1) {
            ConnectionData item = (ConnectionData) store.get_item (i);
            if (!data.connections.has_key (item.id)) {
                store.remove (i);
            } else {
                store.splice (i, 1, {item});
                to_append.remove (item.id);
            }
         }

        // Addend New Connections
        foreach (string id in to_append) {
            store.append (data.connections[id]);
        }
    }
}
