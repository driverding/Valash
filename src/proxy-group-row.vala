/* proxy-group-row.vala
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

[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxy-group-row.ui")]
class Valash.ProxyGroupRow : Adw.ExpanderRow {
    [GtkChild]
    private unowned Gtk.FlowBox flow_box;
    
    public string name { get; construct; }
    private Gee.HashMap<string, ProxyButtonBox> proxy_buttons;

    construct {
        proxy_buttons = new Gee.HashMap<string, ProxyButtonBox> ();
    }

    public ProxyGroupRow.from_data (string name, Gee.HashMap<string, ProxyData> data) {
        Object (name: name);
        refresh (data);
    }

    public void refresh (Gee.HashMap<string, ProxyData> data) {
        this.title = name;
        this.subtitle = _("%d Proxies").printf (data[name].all.length);

        // Proxies - Diff
        var seen = new Gee.HashSet<string> ();

        foreach (string child_name in data[name].all) {
            seen.add (child_name);
            if (proxy_buttons.has_key (child_name)) {
                proxy_buttons[child_name].refresh (data[child_name]);
            } else {
                var new_button = new ProxyButtonBox.from_data (data[child_name]);
                flow_box.append (new_button);
                proxy_buttons.set (child_name, new_button);
            }
        }

        foreach (string child_name in proxy_buttons.keys) {
            if (!seen.contains (child_name)) {
                var button_to_remove = proxy_buttons[child_name];
                flow_box.remove (button_to_remove);
                proxy_buttons.unset (child_name);
            }
        }
    }

    [GtkCallback]
    private void on_delay_check_button_clicked (Gtk.Button source) {
    }
}
