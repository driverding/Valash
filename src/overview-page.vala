[GtkTemplate (ui = "/com/github/driverding/Valash/ui/overview-page.ui")]
class Valash.OverviewPage : Gtk.Box {
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

    private Clash instance;

    public OverviewPage () {
        Object ();
    }

    construct {
        this.instance = Clash.get_instance ();

        start_connections ();
    }

    private void start_connections () {
        instance.start_traffic.begin ();
        instance.start_memory.begin ();

        instance.traffic_received.connect (on_traffic_received);
        instance.memory_received.connect (on_memory_received);
    }

    private void on_traffic_received (TrafficChunk chunk) {
        download_graph.push_data_point (chunk.down);
        upload_graph.push_data_point (chunk.up);

        double max_down = download_graph.get_max_value ();
        double max_up = upload_graph.get_max_value ();

        download_speed_label.label = "%s/s - Max: %s/s".printf(
            format_value(chunk.down),
            format_value(max_down)
        );

        upload_speed_label.label = "%s/s - Max: %s/s".printf(
            format_value(chunk.up),
            format_value(max_up)
        );
    }

    private void on_memory_received (MemoryChunk chunk) {
        memory_usage_label.label      = format_value (chunk.inuse);
    }

    public void on_connections_received (ConnectionsData data) {
        total_downloads_label.label   = format_value (data.download_total);
        total_uploads_label.label     = format_value (data.upload_total);
        connections_count_label.label = "%u".printf(data.connections.size);
    }

    private bool tun_switch_lock = false;
    [GtkCallback]
    private void on_tun_switch_notify_active (GLib.Object sender, GLib.ParamSpec pspec) {
        Adw.SwitchRow source = (Adw.SwitchRow) sender;
        if (tun_switch_lock == true) return;
        tun_switch_lock = true;
        source.sensitive = false;
        configure_tun.begin (source, source.active);
    }

    private async void configure_tun (Adw.SwitchRow source, bool settings) {
        bool success = yield instance.configure_tun (settings, null);
        if (!success) {
            source.active = !source.active;
        }
        source.sensitive = true;
        tun_switch_lock = false;
    }

    [GtkCallback]
    private void on_reload_config_button_clicked (Gtk.Button source) {
        instance.send_reload ();
    }

    [GtkCallback]
    private void on_restart_button_clicked (Gtk.Button source) {
        instance.send_restart ();
    }
}

