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
    private unowned Gtk.FlowBox flow_box;

    private Gee.HashMap<string, ProxyButtonBox> proxy_buttons;

    construct {
        proxy_buttons = new Gee.HashMap<string, ProxyButtonBox> ();
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

        // Proxies - Diff
        var seen = new Gee.HashSet<string> ();

        foreach (ProxyData proxy in data.proxies.values) {
            seen.add (proxy.id);
            if (proxy_buttons.has_key (proxy.id)) {
                proxy_buttons[proxy.id].refresh (proxy);
            } else {
                var new_button = new ProxyButtonBox.from_data (proxy);
                flow_box.append (new_button);
                proxy_buttons.set (proxy.id, new_button);
            }
        }

        foreach (string id in proxy_buttons.keys) {
            if (!seen.contains (id)) {
                var button_to_remove = proxy_buttons[id];
                flow_box.remove (button_to_remove);
                proxy_buttons.unset (id);
            }
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
