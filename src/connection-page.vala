class Valash.ConnectionPage : Gtk.Box {
    private Gtk.ScrolledWindow scrolled_window;
    private GLib.ListStore store;
    private Gtk.SingleSelection selection;
    private Gtk.ColumnView view;


    public ConnectionPage () {
        Object ();
    }

    construct {
        scrolled_window = new Gtk.ScrolledWindow ();
        store = new GLib.ListStore (typeof (ConnectionData));
        selection = new Gtk.SingleSelection (store);
        selection.autoselect = false;
        view = new Gtk.ColumnView (selection);
        view.hexpand = true;

        append_column (_("Host"), null, (data) => {
            return "%s:%s".printf (data.metadata.host, data.metadata.destination_port);
        });
        append_column (_("Chains"), null, (data) => {
            return string.joinv (" <- ", data.chains);
        });
        append_column (_("Download"), 100, (data) => {
            return format_value (data.download);
        });
        append_column (_("Upload"), 100, (data) => {
            return format_value (data.upload);
        });

        scrolled_window.set_child (view);
        this.append (scrolled_window);
    }

    delegate string Formatter (ConnectionData data);

    private void append_column (string title, int? fixed_width, Formatter formatter) {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((item) => {
            var list_item = (Gtk.ListItem) item;
            var inscription = new Gtk.Inscription (null);
            list_item.set_child (inscription);
        });
        factory.bind.connect ((factory, item) => {
            var list_item = (Gtk.ListItem) item;
            Gtk.Inscription inscription = (Gtk.Inscription) list_item.get_child ();
            ConnectionData data = (ConnectionData) list_item.get_item ();
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
