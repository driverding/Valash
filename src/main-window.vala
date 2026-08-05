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


    private uint connections_request_handler = 0;

    static construct {
        typeof (Valash.Graph).ensure ();
        typeof (Valash.ConnectionView).ensure ();
    }

    construct {
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
    }

    private void error_encountered (string message) {
        overlay.add_toast (new Adw.Toast (message));
    }

    private void resize_record () {
        while (download_record.size > record_length) download_record.poll_head ();
        while (download_record.size < record_length) download_record.offer_head (0);

        while (download_record.size > record_length) download_record.poll_head ();
        while (download_record.size < record_length) download_record.offer_head (0);
    }

    private void traffic_received (TrafficChunk traffic) {
        download_record.poll ();
        download_record.offer (traffic.down);
        download_graph.refresh ();

        upload_record.poll ();
        upload_record.offer (traffic.up);
        upload_graph.refresh ();

        GLib.CompareDataFunc<double?> compare_func = (a, b) => { return a > b ? 1 : a == b ? 0 : -1; };
        double max_down = download_record.max (compare_func);
        double max_up = upload_record.max (compare_func);

        download_speed_label.label = _("%s/s - Max: %s/s").printf(format_value(traffic.down),
                                                                  format_value(max_down));
        upload_speed_label.label = _("%s/s - Max: %s/s").printf(format_value(traffic.up),
                                                                format_value(max_up));
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
        ConnectionsData data = yield clash.request_connections (connections_cancellable);

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
        var data = yield clash.request_proxies (null);

        
    }

    private async void refresh_proxy_providers () {
    
    }










    [GtkCallback]
    private void on_refresh_button_clicked (Gtk.Button source) {
        restart_traffic_memory ();
    }

    [GtkCallback]
    private void on_tun_switch_notify_active (GLib.Object sender, GLib.ParamSpec pspec) {
        Adw.SwitchRow source = (Adw.SwitchRow) sender;
        source.sensitive = false;
        configure_tun.begin (source, source.active);
    }

    private async void configure_tun (Adw.SwitchRow source, bool setting) {
        bool success = yield clash.configure_tun (setting, null);
        if (!success) {
            source.active = !source.active;
        }
        source.sensitive = true;
    }

    [GtkCallback]
    private void on_global_switch_notify_active (GLib.Object sender, GLib.ParamSpec pspec) {

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

    }
}
