/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

public class Valash.Clash: Object {
    private Soup.Session session;
    public string url       { get; private set; }
    public string secret    { get; private set; }
    public string delay_url { get; private set; }
    public int    timeout   { get; private set; }

    public signal void error_encountered (string message);

    construct {
        session = new Soup.Session.with_options ("max_conns", 10, "max_conns_per_host", 10);
    }

    public void configure (string url, string secret, string delay_url, int timeout) {
        this.url       = url;
        this.secret    = secret;
        this.delay_url = delay_url;
        this.timeout   = timeout;
    }

    private inline void warn_error (Error e) {
        error_encountered (e.message);
        GLib.warning (e.message);
    }
    
    // Test
    public async bool test_validity (string url, string secret, out string error) {
        Soup.Message message = new Soup.Message ("GET", url);
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, null);
            string content = (string) response.get_data ();
            if (content == null) {
                error = _("NULL response");
                return false;
            } else if (content.strip () != "{\"hello\":\"mihomo\"}" && content.strip () != "{\"hello\":\"clash\"}") {
                error = _("Unrecognizable response: %s").printf (content.strip ());
                return false;
            }
            return true;
        } catch (Error e) {
            error = e.message;
            GLib.warning (e.message);
            return false;
        }
    }


    /*********************** Traffic ***********************/
    public signal void traffic_received (TrafficChunk traffic);
    public GLib.Cancellable? traffic_cancellable;

    public async void start_traffic () {
        Soup.Message message = new Soup.Message ("GET", url + "/traffic");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");

        traffic_cancellable = new GLib.Cancellable ();
        try {
            InputStream stream = yield session.send_async (message, Priority.DEFAULT, traffic_cancellable);
            DataInputStream data_stream = new DataInputStream (stream);
            traffic_loop.begin (data_stream);
        } catch (Error e) {
            warn_error (e);
            return;
        }
    }

    private async void traffic_loop (DataInputStream stream) {
        try {
            while (true) {
                size_t length;
                string chunk = yield stream.read_line_async (Priority.DEFAULT, traffic_cancellable, out length);
                if (length == 0) {
                    GLib.message ("Empty Chunk Received");
                    break;
                }
                TrafficChunk traffic = (TrafficChunk) Json.gobject_from_data (typeof (TrafficChunk), chunk);
                traffic_received (traffic);
            }
        } catch (Error e) {
            if (!(e is IOError.CANCELLED))
                warn_error (e);
            return;
        }
    }


    /*********************** Memory ***********************/
    public signal void memory_received (MemoryChunk memory);
    public GLib.Cancellable? memory_cancellable;

    public async void start_memory () {
        Soup.Message message = new Soup.Message ("GET", this.url + "/memory");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");

        memory_cancellable = new GLib.Cancellable ();
        try {
            InputStream stream = yield session.send_async (message, Priority.DEFAULT, memory_cancellable);
            DataInputStream data_stream = new DataInputStream (stream);
            memory_loop.begin (data_stream);
        } catch (Error e) {
            warn_error (e);
            return;
        }
    }

    private async void memory_loop (DataInputStream stream) {
        try {
            while (true) {
                size_t length;
                string chunk = yield stream.read_line_async (Priority.DEFAULT, memory_cancellable, out length);
                if (length == 0) {
                    GLib.message ("Empty Chunk Received");
                    break;
                }
                MemoryChunk memory = (MemoryChunk) Json.gobject_from_data (typeof (MemoryChunk), chunk);
                memory_received (memory);
            }
        } catch (Error e) {
            if (!(e is IOError.CANCELLED))
                warn_error (e);
            return;
        }
    }


    /*********************** Requests ***********************/
    public async ConnectionsData? request_connections (GLib.Cancellable? cancellable) {
        Soup.Message message = new Soup.Message ("GET", this.url + "/connections");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, cancellable);
            string content = (string) response.get_data ();
            ConnectionsData result =  (ConnectionsData) Json.gobject_from_data (typeof (ConnectionsData), content);
            return result;
        } catch (Error e) {
            warn_error (e);
            return null;
        }
    }

    public async Gee.HashMap<string, ProxyData>? request_proxies (GLib.Cancellable? cancellable) {
        Gee.HashMap<string, ProxyData> result = new Gee.HashMap<string, ProxyData> ();
        Soup.Message message = new Soup.Message ("GET", this.url + "/proxies");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, cancellable);
            Json.Object proxies_obj = Json.from_string ((string) response.get_data ()).get_object ().get_object_member ("proxies");
            proxies_obj.foreach_member ((obj, name, node) => {
                var data = (ProxyData) Json.gobject_deserialize (typeof (ProxyData), node);
                result.set (name, data);
            });
            return result;
        } catch (Error e) {
            warn_error (e);
            return null;
        }
    }

    public async int request_proxy_delay (string proxy, GLib.Cancellable? cancellable) {
        Soup.Message message = new Soup.Message ("GET", this.url + @"/proxies/$(proxy)/delay?url=$(this.delay_url)&timeout=$(this.timeout)");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, cancellable);
            var obj = Json.from_string ((string) response.get_data ()).get_object ();
            return obj.has_member ("delay") ? (int) obj.get_int_member ("delay") : 0;
        } catch (Error e) {
            warn_error (e);
            return 0;
        }
    }

    public async Gee.HashMap<string, ProxyProviderData>? request_proxy_providers (GLib.Cancellable? cancellable) {
        Gee.HashMap<string, ProxyProviderData> result = new Gee.HashMap<string, ProxyProviderData> ();
        Soup.Message message = new Soup.Message ("GET", this.url + "/providers/proxies");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, cancellable);
            Json.Object providers_obj = Json.from_string ((string) response.get_data ()).get_object ().get_object_member ("providers");
            providers_obj.foreach_member ((obj, name, node) => {
                result.set (name, (ProxyProviderData) Json.gobject_deserialize (typeof (ProxyProviderData), node));
            });
            return result;
        } catch (Error e) {
            warn_error (e);
            return null;
        }
    }

    public async void request_proxy_providers_healthcheck (string provider, GLib.Cancellable? cancellable) {
        Soup.Message message = new Soup.Message ("GET", this.url + "/providers/proxies/${provider}/healthcheck");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        try {
            yield session.send_async (message, Priority.DEFAULT, cancellable);
        } catch (Error e) {
            warn_error (e);
        }
    }

    public async bool configure_tun (bool setting, GLib.Cancellable? cancellable) {
        string body = @"{\"tun\": {\"enable\": $setting}}";
        Soup.Message message = new Soup.Message ("PATCH", this.url + "/configs");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        message.request_headers.set_content_type ("application/json", null);
        message.set_request_body_from_bytes ("application/json", new GLib.Bytes (body.data));
        try {
            yield session.send_async (message, Priority.DEFAULT, cancellable);
            return 200 <= message.status_code < 300;
        } catch (Error e) {
            warn_error (e);
            return false;
        }
    }

    public async bool set_proxy (string group, string proxy, GLib.Cancellable? cancellable) {
        string body = @"{\"name\": \"$proxy\"}";
        Soup.Message message = new Soup.Message ("PUT", this.url + "/proxies/" + group);
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        message.request_headers.set_content_type ("application/json", null);
        message.set_request_body_from_bytes ("application/json", new GLib.Bytes (body.data));
        try {
            yield session.send_async (message, Priority.DEFAULT, cancellable);
            return 200 <= message.status_code < 300;
        } catch (Error e) {
            warn_error (e);
            return false;
        }
    }

    public void send_restart () {
        Soup.Message message = new Soup.Message ("POST", this.url + "/restart");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        session.send_async.begin (message, Priority.DEFAULT, null);
    }

    public void send_reload () {
        Soup.Message message = new Soup.Message ("POST", this.url + "/upgrade");
        if (secret != "") message.request_headers.append ("Authorization", @"Bearer $(secret)");
        session.send_async.begin (message, Priority.DEFAULT, null);
    }
}
