/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

 public class Valash.ConnectionModel : Object {
    public string   id               { get; construct; }
    public string   host             { get; set; }
    public string   destination_port { get; set; }
    public double   download         { get; set; }
    public double   upload           { get; set; }
    public string[] chains           { get; set; }

    public ConnectionModel.from_json (ConnectionData data) {
        Object (id: data.id,
                host: data.metadata.host,
                destination_port: data.metadata.destination_port,
                download: data.download,
                upload: data.upload,
                chains: data.chains);
    }

    public void sync_from_json (ConnectionData data) {
        this.host = data.metadata.host;
        this.destination_port = data.metadata.destination_port;
        this.download = data.download;
        this.upload = data.upload;
        this.chains = data.chains;
    }
}

class Valash.ConnectionView : Adw.Bin {
    private Gtk.SortListModel sort_model;
    private Gtk.SingleSelection selection_model;

    private Gtk.ColumnView view;

    construct {
        view = new Gtk.ColumnView (null) { hexpand = true };
        sort_model = new Gtk.SortListModel (null, view.get_sorter ());
        selection_model = new Gtk.SingleSelection (sort_model) { autoselect = false };
        view.set_model (selection_model);

        append_column (_("Host"), (data) => {
            return "%s:%s".printf (data.host, data.destination_port);
        }, new Gtk.StringSorter (new Gtk.PropertyExpression (typeof (ConnectionModel), null, "host")));
        append_column (_("Chains"), (data) => {
            return string.joinv (" <- ", data.chains);
        });
        append_column (_("Download"), (data) => {
            return format_value (data.download);
        }, new Gtk.NumericSorter (new Gtk.PropertyExpression (typeof (ConnectionModel), null, "download")), 100);
        append_column (_("Upload"), (data) => {
            return format_value (data.upload);
        }, new Gtk.NumericSorter (new Gtk.PropertyExpression (typeof (ConnectionModel), null, "upload")), 100);

        this.set_child (view);
    }

    public void set_model (GLib.ListModel model) {
        sort_model.set_model (model);
    }

    public ConnectionView (Gtk.SelectionModel model) {
        Object ();
        this.view.set_model (model);
    }

    private delegate string Formatter (ConnectionModel data);

    private void append_column (string title, Formatter formatter, Gtk.Sorter? sorter = null, int? fixed_width = null) {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((item) => {
            var list_item = (Gtk.ListItem) item;
            var inscription = new Gtk.Inscription (null);
            list_item.set_child (inscription);
        });
        factory.bind.connect ((factory, item) => {
            var list_item = (Gtk.ListItem) item;
            var inscription = (Gtk.Inscription) list_item.get_child ();
            var data = (ConnectionModel) list_item.get_item ();

            ulong handler_id = data.notify.connect (() => { inscription.text = formatter (data); });
            list_item.set_data<ulong> ("notify-handler", handler_id);

            inscription.text = formatter (data);
        });
        factory.unbind.connect ((factory, item) => {
            var list_item = (Gtk.ListItem) item;
            var data = (ConnectionModel) list_item.get_item ();

            // TODO: Check does this fucks up?
            ulong handler = list_item.get_data<ulong> ("notify-handler");
            if (handler != 0) {
                SignalHandler.disconnect (data, handler);
            }
        });
        var column = new Gtk.ColumnViewColumn (title, factory);
        if (fixed_width == null) {
            column.expand = true;
        } else {
            column.set_fixed_width (fixed_width);
        }

        if (sorter != null) {
            column.set_sorter (sorter);
        }

        view.append_column (column);
    }
}
