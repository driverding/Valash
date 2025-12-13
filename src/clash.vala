/* --- DATA TYPES --- */

public class Valash.TrafficChunk : GLib.Object {
    public double  up                 { get; set; }
    public double  down               { get; set; }
}

public class Valash.MemoryChunk : GLib.Object {
    public double  inuse              { get; set; }
    public double  oslimit            { get; set; }
}

public class Valash.ConnectionMetadata : GLib.Object, Json.Serializable {
    public string  network            { get; set; }
    public string  connection_type    { get; set; }  // Name Conflict, type <=> connection_type
    public string  source_ip          { get; set; }
    public string  destination_ip     { get; set; }
    public string? source_geo_ip      { get; set; }
    public string? destination_geo_ip { get; set; }
    public string  source_ip_asn      { get; set; }
    public string  destination_ip_asn { get; set; }
    public string  source_port        { get; set; }
    public string  destination_port   { get; set; }
    public string  inbound_ip         { get; set; }
    public string  inbound_port       { get; set; }
    public string  inbound_name       { get; set; }
    public string  inbound_user       { get; set; }
    public string  host               { get; set; }
    public string  dns_mode           { get; set; }
    public int     uid                { get; set; }
    public string  process            { get; set; }
    public string  process_path       { get; set; }
    public string  special_proxy      { get; set; }
    public string  special_rules      { get; set; }
    public string  remote_destination { get; set; }
    public int     dscp               { get; set; }
    public string  sniff_host         { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        if (name == "type") return get_class ().find_property ("connection_type");
        return get_class ().find_property (camel_to_snake (name));
    }
}


public class Valash.ConnectionData : GLib.Object, Json.Serializable {
    public ConnectionMetadata metadata { get; set; }
    public string[] chains       { get; set; }
    public string   id           { get; set; }
    public double   upload       { get; set; }
    public double   download     { get; set; }
    public string   start        { get; set; }
    public string   rule         { get; set; }
    public string   rule_payload { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        return get_class ().find_property (camel_to_snake (name));
    }
}

public class Valash.ConnectionsData : GLib.Object, Json.Serializable {
    public Gee.HashMap<string, ConnectionData> connections { get; set; } // TODO: Convert to HashTable Perhaps
    public double download_total { get; set; }
    public double upload_total   { get; set; }
    public double memory         { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        return get_class ().find_property (camel_to_snake (name));
    }

    public override bool deserialize_property (
        string property_name,
        out Value value,
        ParamSpec pspec,
        Json.Node property_node
    ) {
        if (property_name == "connections") {
            value = Value (typeof (Gee.HashMap));
            Json.Array arr = property_node.get_array ();
            Gee.HashMap<string, ConnectionData> result = new Gee.HashMap<string, ConnectionData> ();

            for (int i = 0; i < arr.get_length (); i += 1) {
                Json.Node node = arr.get_element (i);
                ConnectionData data = (ConnectionData) Json.gobject_deserialize (typeof (ConnectionData), node);
                result.set (data.id, data);
            }
            value.set_object (result);
            return true;
        }

        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}


public class Valash.HealthHistory : GLib.Object, Json.Serializable {
    public GLib.DateTime time { get; set; }
    public double delay       { get; set; } // Delay == 0 represents infinite delay

    public override bool deserialize_property (
        string property_name,
        out Value value,
        ParamSpec pspec,
        Json.Node property_node
    ) {
        if (property_name == "time") {
            value = Value (typeof (GLib.DateTime));
            GLib.DateTime result = new GLib.DateTime.from_iso8601 (property_node.get_string (), new GLib.TimeZone.local ());
            value.set_boxed (result);
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}

public class Valash.ProxyData : GLib.Object, Json.Serializable {
    public string[]     all              { get; set; }
    public Gee.ArrayList<HealthHistory> history { get; set; } // TODO: This will be the healthcheck result?
    public bool         alive            { get; set; }
    public string       dialer_proxy     { get; set; }
    // public Json.Object  extra            { get; set; } // TODO: This does not work, rewrite it in the future
    public bool         hidden           { get; set; }
    public string       icon             { get; set; }
    public string       proxy_interface  { get; set; }
    public bool         mptcp            { get; set; }
    public string       name             { get; set; }
    public string       now              { get; set; }
    public int          routing_mark     { get; set; }
    public bool         smux             { get; set; }
    public string       test_url         { get; set; }
    public bool         tfo              { get; set; }
    public string       proxy_type       { get; set; }
    public bool         udp              { get; set; }
    public bool         uot              { get; set; }
    public bool         xudp             { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        if (name == "type") return get_class ().find_property ("proxy_type");
        return get_class ().find_property (camel_to_snake (name));
    }

    public override bool deserialize_property (
        string property_name,
        out Value value,
        ParamSpec pspec,
        Json.Node property_node
    ) {
        if (property_name == "history") {
            value = Value (typeof (Gee.ArrayList));
            Gee.ArrayList<HealthHistory> result = new Gee.ArrayList<HealthHistory> ();
            Json.Array arr = property_node.get_array ();

            for (int i = 0; i < arr.get_length (); i += 1) {
                Json.Node node = arr.get_element (i);
                HealthHistory data = (HealthHistory) Json.gobject_deserialize (typeof (HealthHistory), node);
                result.add (data);
            }
            value.set_object (result);
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}

public class Valash.SubscriptionInfo : GLib.Object, Json.Serializable {
    public double upload        { get; set; }
    public double download      { get; set; }
    public double total         { get; set; }
    public GLib.DateTime? expire { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        return get_class ().find_property (name.down ());
    }

    public override bool deserialize_property (
        string property_name,
        out Value value,
        ParamSpec pspec,
        Json.Node property_node
    ) {
        if (property_name == "expire") {
            int64 unix_time = property_node.get_int ();
            if (unix_time == 0)
                return false;
            value = Value (typeof (GLib.DateTime));
            GLib.DateTime result = new GLib.DateTime.from_unix_utc (unix_time);
            value.set_boxed (result);
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}

public class Valash.ProxyProviderData : GLib.Object, Json.Serializable {
    public SubscriptionInfo? subscription_info { get; set; }
    public Gee.ArrayList<ProxyData> proxies    { get; set; }
    public string name              { get; set; }
    public string provider_type     { get; set; }
    public string vehicle_type      { get; set; }
    public string test_url          { get; set; }
    public string expected_status   { get; set; }
    public GLib.DateTime updated_at { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        if (name == "type") return get_class ().find_property ("proxy_type");
        return get_class ().find_property (camel_to_snake (name));
    }

    public override bool deserialize_property (
        string property_name,
        out Value value,
        ParamSpec pspec,
        Json.Node property_node
    ) {
        if (property_name == "proxies") {
            value = Value (typeof (Gee.ArrayList));
            Gee.ArrayList<ProxyData> result = new Gee.ArrayList<ProxyData> ();
            Json.Array arr = property_node.get_array ();

            for (int i = 0; i < arr.get_length (); i += 1) {
                Json.Node node = arr.get_element (i);
                ProxyData data = (ProxyData) Json.gobject_deserialize (typeof (ProxyData), node);
                result.add (data);
            }
            value.set_object (result);
            return true;
        } else if (property_name == "updated-at") {
            value = Value (typeof (GLib.DateTime));
            GLib.DateTime result = new GLib.DateTime.from_iso8601 (property_node.get_string (), new GLib.TimeZone.local ());
            value.set_boxed (result);
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}

/* --- CLASH INTERFACE --- */

public class Valash.Clash : Object {
    private static Clash? instance;

    private Soup.Session session;
    public string url       { set; get; }
    public string delay_url { set; get; }
    public int timeout      { set; get; }

    private Clash (string url, string delay_url, int timeout) {
        session = new Soup.Session.with_options ("max_conns", 10, "max_conns_per_host", 10);
        this.url = url;
        this.delay_url = delay_url;
        this.timeout = timeout;
    }

    public static Clash reinit_instance (string url, string delay_url, int timeout) {
        instance = new Clash (url, delay_url, timeout);
        return instance;
    }

    public static Clash get_instance () {
        if (instance == null) GLib.critical ("Clash interface is not initialized!");
        return instance;
    }

    // Traffic
    public GLib.Cancellable? traffic_cancellable;

    public async void start_traffic () {
        Soup.Message message = new Soup.Message ("GET", url + "/traffic");
        traffic_cancellable = new GLib.Cancellable ();
        try {
            InputStream stream = yield session.send_async (message, Priority.DEFAULT, traffic_cancellable);

            traffic_loop.begin (stream);
        } catch (Error e) {
            GLib.warning (e.message);
            return;
        }
    }

    private async void traffic_loop (InputStream stream) {
        uint8[] buf = new uint8[32];
        try {
            while (true) {
                ssize_t n = yield stream.read_async (buf, Priority.DEFAULT, traffic_cancellable);
                if (n == 0) {
                    GLib.message ("Empty Chunk Received");
                    break;
                }
                string chunk = ((string) buf[0 : n])[0 : n];
                TrafficChunk traffic = (TrafficChunk) Json.gobject_from_data (typeof (TrafficChunk), chunk);
                traffic_received (traffic);
            }
        } catch (Error e) {
            if (!(e is IOError.CANCELLED)) GLib.warning (e.message);
            return;
        }
    }

    public signal void traffic_received (TrafficChunk traffic);


    // Memory
    public GLib.Cancellable? memory_cancellable;

    public async void start_memory () {
        Soup.Message message = new Soup.Message ("GET", this.url + "/memory");
        memory_cancellable = new GLib.Cancellable ();
        try {
            InputStream stream = yield session.send_async (message, Priority.DEFAULT, memory_cancellable);
            memory_loop.begin (stream);
        } catch (Error e) {
            GLib.warning (e.message);
            return;
        }
    }

    private async void memory_loop (InputStream stream) {
        uint8[] buf = new uint8[32];
        try {
            while (true) {
                ssize_t n = yield stream.read_async (buf, Priority.DEFAULT, memory_cancellable);
                if (n == 0) {
                    GLib.message ("Empty Chunk Received");
                    break;
                }
                string chunk = ((string) buf[0 : n])[0 : n];
                MemoryChunk memory = (MemoryChunk) Json.gobject_from_data (typeof (MemoryChunk), chunk);
                memory_received (memory);
            }
        } catch (Error e) {
            if (!(e is IOError.CANCELLED)) GLib.warning (e.message);
            return;
        }
    }

    public signal void memory_received (MemoryChunk memory);

    // Connections
    public async ConnectionsData? request_connections (GLib.Cancellable? cancellable) {
        Soup.Message message = new Soup.Message ("GET", this.url + "/connections");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, cancellable);
            string content = (string) response.get_data ();
            ConnectionsData result =  (ConnectionsData) Json.gobject_from_data (typeof (ConnectionsData), content);
            return result;
        } catch (Error e) {
            GLib.warning (e.message);
            return null;
        }
    }

    // Proxies
    public async Gee.HashMap<string, ProxyData>? request_proxies (GLib.Cancellable? cancellable) {
        Gee.HashMap<string, ProxyData> result = new Gee.HashMap<string, ProxyData> ();
        Soup.Message message = new Soup.Message ("GET", this.url + "/proxies");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, cancellable);
            Json.Object proxies_obj = Json.from_string ((string) response.get_data ()).get_object ().get_object_member ("proxies");
            proxies_obj.foreach_member ((obj, name, node) => {
                result.set (name, (ProxyData) Json.gobject_deserialize (typeof (ProxyData), node));
            });
            return result;

        } catch (Error e) {
            GLib.warning (e.message);
            return null;
        }
    }

    // Proxy Delay
    public async double request_proxy_delay (string proxy, GLib.Cancellable? cancellable) {
        Soup.Message message = new Soup.Message ("GET", this.url + "/proxies/${proxy}/delay?url=${this.delay_url}&timeout=${this.timeout}");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, cancellable);
            return Json.from_string ((string) response.get_data ()).get_object ().get_double_member ("delay");
        } catch (Error e) {
            GLib.warning (e.message);
            return 0;
        }
    }

    // Proxies Providers
    public async Gee.HashMap<string, ProxyProviderData>? request_proxy_providers (GLib.Cancellable? cancellable) {
        Gee.HashMap<string, ProxyProviderData> result = new Gee.HashMap<string, ProxyProviderData> ();
        Soup.Message message = new Soup.Message ("GET", this.url + "/providers/proxies");
        try {
            GLib.Bytes response = yield session.send_and_read_async (message, Priority.DEFAULT, cancellable);
            Json.Object providers_obj = Json.from_string ((string) response.get_data ()).get_object ().get_object_member ("providers");
            providers_obj.foreach_member ((obj, name, node) => {
                result.set (name, (ProxyProviderData) Json.gobject_deserialize (typeof (ProxyProviderData), node));
            });
            return result;

        } catch (Error e) {
            GLib.warning (e.message);
            return null;
        }
    }

    // Health Check
    public async void request_proxy_providers_healthcheck (string provider, GLib.Cancellable? cancellable) {
        Soup.Message message = new Soup.Message ("GET", this.url + "/providers/proxies/${provider}/healthcheck");
        try {
            yield session.send_async (message, Priority.DEFAULT, cancellable);
        } catch (Error e) {
            GLib.warning (e.message);
        }
    }

    // Configs
    public async bool configure_tun (bool setting, GLib.Cancellable? cancellable) {
        string body = @"{\"tun\": {\"enable\": $setting}}";
        Soup.Message message = new Soup.Message ("PATCH", this.url + "/configs");
        message.request_headers.set_content_type ("application/json", null);
        message.set_request_body_from_bytes ("application/json", new GLib.Bytes (body.data));
        try {
            yield session.send_async (message, Priority.DEFAULT, cancellable);
            return 200 <= message.status_code < 300;
        } catch (Error e) {
            GLib.warning (e.message);
            return false;
        }
    }

    public void send_restart () {
        Soup.Message message = new Soup.Message ("POST", this.url + "/restart");
        session.send_async.begin (message, Priority.DEFAULT, null);
    }

    public void send_reload () {
        Soup.Message message = new Soup.Message ("POST", this.url + "/upgrade");
        session.send_async.begin (message, Priority.DEFAULT, null);
    }


}
