/* proxy-button-box.vala
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

namespace Valash {
    delegate void SelectingProxyHandler ();
}

[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxy-button-box.ui")]
class Valash.ProxyButtonBox : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Label name_label;
    [GtkChild]
    private unowned Gtk.Label proxy_type_label;
    [GtkChild]
    private unowned Gtk.Label delay_label;

    construct {

    }

    public ProxyButtonBox.from_data (ProxyData data) {
        refresh (data);
    }

    public void refresh (ProxyData data) {
        name_label.label = data.name;
        proxy_type_label.label = data.proxy_type;
        int latest_delay = get_latest_delay (data.history);
        delay_label.label = latest_delay == 0 ? "-" : "%dms".printf (latest_delay); // Get the newest
    }

    private int get_latest_delay (Gee.ArrayList<HealthHistory> histories) {
        if (histories.is_empty)
            return 0;

        int index = 0;
        GLib.DateTime latest = histories[0].time;

        for (int i = 1; i < histories.size; i += 1) {
            if (latest.compare (histories[i].time) < 0) {
                index = i;
                latest = histories[i].time;
            }
        }
        return histories[index].delay;
    }

    [GtkCallback]
    private void on_select_button_clicked (Gtk.Button source) {
        // TODO
    }

    [GtkCallback]
    private void on_refresh_button_clicked (Gtk.Button source) {
        // TODO

    }
}
