/* proxy-provider-row.vala
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

[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxy-provider-row.ui")]
class Valash.ProxyProviderRow : Adw.ExpanderRow {
    [GtkChild]
    private unowned Gtk.ProgressBar usage_progress_bar;
    [GtkChild]
    private unowned Gtk.Label right_label;
    [GtkChild]
    private unowned Gtk.GridView view;

    private GLib.ListStore store;
    private Gtk.NoSelection selection;

    construct {
        store = new GLib.ListStore (typeof (ProxyData));
        selection = new Gtk.NoSelection (store);
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((item) => {
            var list_item = (Gtk.ListItem) item;
            var button_box = new ProxyButtonBox ();
            list_item.set_child (button_box);
        });
        factory.bind.connect ((factory, item) => {
            var list_item = (Gtk.ListItem) item;
            var button_box = (ProxyButtonBox) list_item.get_child ();
            var data = (ProxyData) list_item.get_item ();
            button_box.refresh (data);
        });
        view.set_factory (factory);
        view.set_model (selection);
        // view = new Gtk.GridView (selection, factory) { hexpand = true };
        // view.add_css_class ("no-bg");
        // expander_box.append (view);
    }

    public ProxyProviderRow.from_data (ProxyProviderData data) {
        refresh (data);
    }

    public void refresh (ProxyProviderData data) {
        // Left Label
        this.title = data.name;
        this.subtitle =
            data.vehicle_type + " - "
            + _("%d Proxies").printf (data.proxies.size) + " - "
            + data.updated_at.format (_("Updated on %b. %-d"));

        // Proxies
        // Mark All Proxies
        Gee.HashSet<string> to_append = new Gee.HashSet<string> ();
        foreach (string id in data.proxies.keys) {
            to_append.add (id);
        }

        // Remove Disappeared Proxies, Splice Existing Proxies
        for (int i = (int) store.get_n_items () - 1; i >= 0; i -= 1) {
            ProxyData item = (ProxyData) store.get_item (i);
            if (!data.proxies.has_key (item.id)) {
                store.remove (i);
            } else {
                store.splice (i, 1, {item});
                to_append.remove (item.id);
            }
         }

        // Addend New Connections
        foreach (string id in to_append) {
            store.append (data.proxies[id]);
        }

        // Right Label
        string to_right_label = "";
        if (data.subscription_info != null) {
            if (data.subscription_info.expire != null) {
                to_right_label = data.subscription_info.expire.format ("Expire on %Y %b. %-d");
            }

            if (data.subscription_info.download != 0 && data.subscription_info.upload != 0 && data.subscription_info.total != 0) {
                double available = data.subscription_info.total - data.subscription_info.download - data.subscription_info.upload;
                double total = data.subscription_info.total;

                usage_progress_bar.visible = true;
                usage_progress_bar.fraction = available / total;

                if (to_right_label != "")
                    to_right_label += " - ";
                to_right_label += format_value (available) + " / " + format_value (total);
            } else {
                usage_progress_bar.visible = false;
            }
        }
        right_label.label = to_right_label;
    }

    [GtkCallback]
    private void on_health_check_button_clicked (Gtk.Button source) {
    }
}
