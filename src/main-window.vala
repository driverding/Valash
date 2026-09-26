/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

[GtkTemplate (ui = "/com/github/driverding/Valash/main-window.ui")]
public class Valash.MainWindow: Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.ToastOverlay overlay;
    [GtkChild]
    private unowned Adw.ViewStack stack;

    /* Overview Page */
    [GtkChild]
    private unowned Gtk.Label download_speed_label;
    [GtkChild]
    private unowned Valash.Graph download_graph;
    [GtkChild]
    private unowned Gtk.Label upload_speed_label;
    [GtkChild]
    private unowned Valash.Graph upload_graph;
    [GtkChild]
    private unowned Gtk.Label total_downloads_label;
    [GtkChild]
    private unowned Gtk.Label total_uploads_label;
    [GtkChild]
    private unowned Gtk.Label connections_count_label;
    [GtkChild]
    private unowned Gtk.Label memory_usage_label;

    /* ProxyPage */
    [GtkChild]
    private unowned Gtk.ListBox proxy_group_listbox;
    [GtkChild]
    private unowned Gtk.ListBox proxy_provider_listbox;

    /* Settings Group */
    [GtkChild]
    private unowned Adw.SwitchRow tun_row;
    [GtkChild]
    private unowned Adw.ComboRow mode_row;

    [GtkChild]
    private unowned Valash.ConnectionView connection_view;


    /* Settings Bind, should never be set */
    public int record_length { get; set; }
    public int update_period { get; set; }

    private Clash clash;
    private Settings settings;

    private GLib.Cancellable connections_cancellable = new GLib.Cancellable ();

    private Gee.ArrayQueue<double?> download_record;
    private Gee.ArrayQueue<double?> upload_record;

    private GLib.ListStore proxy_group_store;
    private GLib.ListStore proxy_provider_store;

    private GLib.ListStore connection_store;

    /* Last known data for every proxy name, from /proxies and the providers */
    private Gee.HashMap<string, ProxyData> proxy_index = new Gee.HashMap<string, ProxyData> ();


    private uint connections_request_handler = 0;
    /* Mode confirmed by the kernel, used to revert a failed change */
    private uint last_mode_index = 0;
    private bool syncing_mode_row = false;
    private bool syncing_tun_row = false;

    static construct {
        typeof (Valash.Graph).ensure ();
        typeof (Valash.ConnectionView).ensure ();
    }

    construct {
        ActionEntry[] action_entries = {
            { "select-proxy", this.on_select_proxy, "(ss)" },
            { "request-group-delay-check", this.on_request_group_delay_check, "s" },
            { "request-delay-check", this.on_request_delay_check, "s" },
        };
        this.add_action_entries (action_entries, this);

        proxy_group_store = new GLib.ListStore (typeof (ProxyGroupModel));
        proxy_provider_store = new GLib.ListStore (typeof (ProxyProviderModel));

        proxy_group_listbox.bind_model (proxy_group_store, (obj) => {
            return new ProxyGroupRow ((ProxyGroupModel) obj);
        });
        proxy_provider_listbox.bind_model (proxy_provider_store, (obj) => {
            return new ProxyProviderRow ((ProxyProviderModel) obj);
        });

        connection_store = new GLib.ListStore (typeof (ConnectionModel));
        connection_view.set_model (connection_store);

        syncing_mode_row = true;
        mode_row.model = new Gtk.StringList ({ _("Rule"), _("Global"), _("Direct") });
        syncing_mode_row = false;

        download_record = new Gee.ArrayQueue<double?> ();
        upload_record = new Gee.ArrayQueue<double?> ();

        download_graph.series = download_record;
        upload_graph.series = upload_record;
    }

    public MainWindow (Adw.Application app, Clash clash, Settings settings) {
        Object (application: app);
        this.clash = clash;
        this.settings = settings;

        settings.bind ("record-length", this, "record-length", SettingsBindFlags.GET);
        settings.bind ("update-period", this, "update-period", SettingsBindFlags.GET);

        this.notify["record-length"].connect (resize_record);
        this.notify["update-period"].connect (reschedule_connections_request);

        for (int i = 0; i < record_length; i += 1) {
            download_record.offer (0);
            upload_record.offer (0);
        }

        clash.error_encountered.connect (error_encountered);
        clash.traffic_received.connect (traffic_received);
        clash.memory_received.connect (memory_received);

        reschedule_connections_request ();
        restart_traffic_memory ();

        refresh_proxies.begin ();
        refresh_settings.begin ();
    }

    private void error_encountered (string message) {
        overlay.add_toast (new Adw.Toast (message));
    }

    private void resize_record () {
        while (download_record.size > record_length) download_record.poll_head ();
        while (download_record.size < record_length) download_record.offer_head (0);

        while (upload_record.size > record_length) upload_record.poll_head ();
        while (upload_record.size < record_length) upload_record.offer_head (0);
    }

    private void traffic_received (TrafficChunk traffic) {
        download_record.poll ();
        download_record.offer (traffic.down);
        download_graph.refresh ();

        upload_record.poll ();
        upload_record.offer (traffic.up);
        upload_graph.refresh ();

        double max_down = download_record.max (compare_double);
        double max_up = upload_record.max (compare_double);

        download_speed_label.label = _("%s/s - Max: %s/s").printf(format_value(traffic.down),
                                                                  format_value(max_down));
        upload_speed_label.label = _("%s/s - Max: %s/s").printf(format_value(traffic.up),
                                                                format_value(max_up));
    }

    private static int compare_double (double? a, double? b) {
        return a > b ? 1 : a == b ? 0 : -1;
    }

    private void memory_received (MemoryChunk memory) {
        memory_usage_label.label      = format_value (memory.inuse);
    }

    private void reschedule_connections_request () {
        if (connections_request_handler != 0) {
            GLib.Source.remove (connections_request_handler);
        }

        connections_request_handler = GLib.Timeout.add (update_period, () => {
            request_connections.begin ();
            return true;
        });
    }

    private async void request_connections () {
        ConnectionsData? data = yield clash.request_connections (connections_cancellable);
        if (data == null) return;

        total_downloads_label.label   = format_value (data.download_total);
        total_uploads_label.label     = format_value (data.upload_total);
        connections_count_label.label = "%u".printf(data.connections.size);

        /* Diff the ConnectionView */
        diff_list_store<string, ConnectionData> (
            connection_store,
            data.connections,
            (item) => ((ConnectionModel) item).id,
            (json) => new ConnectionModel.from_json (json),
            (item, json) => ((ConnectionModel) item).sync_from_json (json)
        );
    }

    private void restart_traffic_memory () {
        if (clash.traffic_cancellable != null) clash.traffic_cancellable.cancel ();
        if (clash.memory_cancellable != null) clash.memory_cancellable.cancel ();
        clash.start_traffic.begin ();
        clash.start_memory.begin ();
    }

    private async void refresh_proxies () {
        var proxies = yield clash.request_proxies (null);
        if (proxies == null) {
            return;
        }
        var providers = yield clash.request_proxy_providers (null);

        /* Since mihomo 1.19.28, /proxies no longer merges proxy-provider nodes,
         * so group members listed in "all" must be resolved against the providers. */
        var members = new Gee.HashMap<string, ProxyData> ();
        foreach (var entry in proxies.entries) {
            members[entry.key] = entry.value;
        }
        if (providers != null) {
            foreach (var provider in providers.values) {
                foreach (var proxy in provider.proxies.values) {
                    if (proxy.name != null && !members.has_key (proxy.name)) {
                        members[proxy.name] = proxy;
                    }
                }
            }
        }
        proxy_index = members;

        /* Filter to only proxy groups (entries with a non-null "all" field) */
        var groups = new Gee.HashMap<string, ProxyData> ();
        foreach (var entry in proxies.entries) {
            if (entry.value.all != null) {
                groups[entry.key] = entry.value;
            }
        }

        diff_list_store<string, ProxyData> (
            proxy_group_store,
            groups,
            (item) => ((ProxyGroupModel) item).proxy_group_name,
            (json) => new ProxyGroupModel.from_json (json, members),
            (item, json) => ((ProxyGroupModel) item).sync_from_json (json, members)
        );

        if (providers != null) {
            populate_proxy_providers (providers);
        }
    }

    private void populate_proxy_providers (Gee.HashMap<string, ProxyProviderData> providers) {
        /* Drop the pseudo providers mihomo generates per proxy group */
        var new_providers = new Gee.HashMap<string, ProxyProviderData>();
        foreach (var entry in providers.entries) {
            if (entry.value.vehicle_type != "Compatible") {
                new_providers[entry.key] = entry.value;
            }
        }
        providers = new_providers;

        diff_list_store<string, ProxyProviderData> (
            proxy_provider_store,
            providers,
            (item) => ((ProxyProviderModel) item).provider_name,
            (json) => new ProxyProviderModel.from_json (json),
            (item, json) => ((ProxyProviderModel) item).sync_from_json (json)
        );
    }







    private void on_select_proxy (SimpleAction action, Variant? parameter) {
        string group, proxy;
        parameter.get ("(ss)", out group, out proxy);
        select_proxy.begin (group, proxy);
    }

    private async void select_proxy (string group, string proxy) {
        bool success = yield clash.set_proxy (group, proxy, null);
        if (!success) {
            overlay.add_toast (new Adw.Toast (_("Failed to select %s in %s").printf (proxy, group)));
        }
        refresh_proxies.begin ();
    }

    private void on_request_group_delay_check (SimpleAction action, Variant? parameter) {
        string group_name = parameter.get_string ();
        string[] proxy_names = {};
        for (uint i = 0; i < proxy_group_store.get_n_items (); i++) {
            var group = (ProxyGroupModel) proxy_group_store.get_item (i);
            if (group.proxy_group_name == group_name) {
                for (uint j = 0; j < group.proxies.get_n_items (); j++) {
                    var proxy = (ProxyModel) group.proxies.get_item (j);
                    proxy_names += proxy.proxy_name;
                }
                break;
            }
        }

        run_delay_checks (proxy_names);
    }

    /* Proxy-provider nodes are not in the global proxy tree, so /proxies/<name>/delay
     * answers 404 for them. Their latency can only be refreshed one provider at a time. */
    private void split_delay_targets (string[] proxy_names,
                                      out Gee.HashSet<string> providers,
                                      out Gee.ArrayList<string> direct) {
        providers = new Gee.HashSet<string> ();
        direct = new Gee.ArrayList<string> ();
        foreach (string name in proxy_names) {
            ProxyData? data = proxy_index[name];
            string provider = data != null ? data.provider_name : null;
            if (provider != null && provider != "") {
                providers.add (provider);
            } else {
                direct.add (name);
            }
        }
    }

    private void run_delay_checks (string[] proxy_names) {
        Gee.HashSet<string> providers;
        Gee.ArrayList<string> direct;
        split_delay_targets (proxy_names, out providers, out direct);

        uint remaining = (uint) providers.size + (uint) direct.size;
        if (remaining == 0) {
            return;
        }

        foreach (string provider in providers) {
            clash.request_proxy_providers_healthcheck.begin (provider, null, (obj, res) => {
                if (!clash.request_proxy_providers_healthcheck.end (res)) {
                    overlay.add_toast (new Adw.Toast (_("Health check failed for %s").printf (provider)));
                }
                delay_check_done (ref remaining);
            });
        }
        foreach (string name in direct) {
            clash.request_proxy_delay.begin (name, null, (obj, res) => {
                clash.request_proxy_delay.end (res);
                delay_check_done (ref remaining);
            });
        }
    }

    private void delay_check_done (ref uint remaining) {
        remaining -= 1;
        if (remaining == 0) {
            overlay.add_toast (new Adw.Toast (_("Update Done")));
            refresh_proxies.begin ();
        }
    }

    private void on_request_delay_check (SimpleAction action, Variant? parameter) {
        run_delay_checks ({ parameter.get_string () });
    }

    [GtkCallback]
    private void on_refresh_button_clicked (Gtk.Button source) {
        restart_traffic_memory ();
        refresh_proxies.begin ();
        refresh_settings.begin ();
    }

    [GtkCallback]
    private void on_tun_switch_notify_active (GLib.Object sender, GLib.ParamSpec pspec) {
        if (syncing_tun_row) return;
        Adw.SwitchRow source = (Adw.SwitchRow) sender;
        source.sensitive = false;
        configure_tun.begin (source, source.active);
    }

    private async void configure_tun (Adw.SwitchRow source, bool setting) {
        bool success = yield clash.configure_tun (setting, null);
        if (!success) {
            overlay.add_toast (new Adw.Toast (_("Failed to change TUN mode")));
            source.active = !source.active;
        }
        source.sensitive = true;
    }

    [GtkCallback]
    private void on_mode_row_notify_selected_item (GLib.Object sender, GLib.ParamSpec pspec) {
        if (syncing_mode_row) return;
        string? mode = mode_from_index (mode_row.selected);
        if (mode == null) return;
        mode_row.sensitive = false;
        set_mode.begin (mode);
    }

    private static string? mode_from_index (uint index) {
        switch (index) {
        case 0: return "rule";
        case 1: return "global";
        case 2: return "direct";
        default: return null;
        }
    }

    private static uint index_of_mode (string mode) {
        switch (mode.down ()) {
        case "global": return 1;
        case "direct": return 2;
        default: return 0;
        }
    }

    private async void set_mode (string mode) {
        bool success = yield clash.set_mode (mode, null);
        if (success) {
            last_mode_index = mode_row.selected;
        } else {
            overlay.add_toast (new Adw.Toast (_("Failed to switch running mode")));
            syncing_mode_row = true;
            mode_row.selected = last_mode_index;
            syncing_mode_row = false;
        }
        mode_row.sensitive = true;
    }

    private async void refresh_settings () {
        ConfigsData? data = yield clash.request_configs (null);
        if (data == null) return;

        syncing_mode_row = true;
        last_mode_index = index_of_mode (data.mode ?? "rule");
        mode_row.selected = last_mode_index;
        syncing_mode_row = false;

        syncing_tun_row = true;
        tun_row.active = data.tun_enabled;
        syncing_tun_row = false;
    }

    [GtkCallback]
    private void on_reload_config_button_clicked (Gtk.Button source) {
        clash.send_reload ();
    }

    [GtkCallback]
    private void on_restart_button_clicked (Gtk.Button source) {
        clash.send_restart ();
    }

    [GtkCallback]
    private void on_update_all_proxy_button_clicked (Gtk.Button source) {
        update_all_proxies ();
    }

    private void update_all_proxies () {
        var proxy_names = new Gee.HashSet<string> ();

        /* Collect all proxy names from groups */
        for (uint i = 0; i < proxy_group_store.get_n_items (); i++) {
            var group = (ProxyGroupModel) proxy_group_store.get_item (i);
            for (uint j = 0; j < group.proxies.get_n_items (); j++) {
                var proxy = (ProxyModel) group.proxies.get_item (j);
                proxy_names.add (proxy.proxy_name);
            }
        }

        /* Collect all proxy names from providers */
        for (uint i = 0; i < proxy_provider_store.get_n_items (); i++) {
            var provider = (ProxyProviderModel) proxy_provider_store.get_item (i);
            for (uint j = 0; j < provider.proxies.get_n_items (); j++) {
                var proxy = (ProxyModel) provider.proxies.get_item (j);
                proxy_names.add (proxy.proxy_name);
            }
        }

        run_delay_checks (proxy_names.to_array ());
    }
}
