/*
 * Copyright (C) 2026 DriverDing
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */
 
 public class Valash.TrafficChunk : GLib.Object, Json.Serializable {
    public double up         { get; set; }
    public double down       { get; set; }
    public double up_total   { get; set; }
    public double down_total { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        return get_class ().find_property (camel_to_kebab (name));
    }
}

public class Valash.MemoryChunk : GLib.Object {
    public double inuse    { get; set; }
    public double oslimit  { get; set; }
}

public class Valash.ConnectionMetadata : GLib.Object, Json.Serializable {
    public string  network                { get; set; }
    public string  connection_type        { get; set; } // Name Conflict, type => connection_type
    public string  source_ip              { get; set; }
    public string  destination_ip         { get; set; }
    public string? source_geo_ip          { get; set; }
    public string? destination_geo_ip     { get; set; }
    public string  source_ip_asn          { get; set; }
    public string  destination_ip_asn     { get; set; }
    public string  source_port            { get; set; }
    public string  destination_port       { get; set; }
    public string  inbound_ip             { get; set; }
    public string  inbound_port           { get; set; }
    public string  inbound_name           { get; set; }
    public string  inbound_user           { get; set; }
    public string  host                   { get; set; }
    public string  dns_mode               { get; set; }
    public int     uid                    { get; set; }
    public string  process                { get; set; }
    public string  process_path           { get; set; }
    public string  special_proxy          { get; set; }
    public string  special_rules          { get; set; }
    public string  remote_destination     { get; set; }
    public int     dscp                   { get; set; }
    public string  sniff_host             { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        if (name == "type") {
            return get_class ().find_property ("connection_type");
        }
        return get_class ().find_property (camel_to_kebab (name));
    }
}

public class Valash.ConnectionData : GLib.Object, Json.Serializable {
    public ConnectionMetadata metadata     { get; set;
        default = new ConnectionMetadata (); }
    public string[]           chains       { get; set;
        default = new string[0]; }
    public string             id           { get; set; }
    public double             upload       { get; set; }
    public double             download     { get; set; }
    public string             start        { get; set; }
    public string             rule         { get; set; }
    public string             rule_payload { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        return get_class ().find_property (camel_to_kebab (name));
    }
}

public class Valash.ConnectionsData : GLib.Object, Json.Serializable {
    public Gee.HashMap<string, ConnectionData> connections    { get; set;
        default = new Gee.HashMap<string, ConnectionData> (); }
    public double                              download_total { get; set; }
    public double                              upload_total   { get; set; }
    public double                              memory         { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        return get_class ().find_property (camel_to_kebab (name));
    }

    public override bool deserialize_property (string property_name,
                                               out Value value,
                                               ParamSpec pspec,
                                               Json.Node property_node) {
        if (property_name == "connections") {
            value = Value (typeof (Gee.HashMap));
            var result = new Gee.HashMap<string, ConnectionData> ();
            
            var arr = property_node.get_array ();
            for (int i = 0; i < arr.get_length (); i += 1) {
                var node = arr.get_element (i);
                var data = (ConnectionData) Json.gobject_deserialize (typeof (ConnectionData), node);
                result.set (data.id, data);
            }
            value.set_object (result);
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}

public class Valash.HealthHistory : GLib.Object, Json.Serializable {
    public GLib.DateTime time  { get; set; }
    public int           delay { get; set; }  // 0 represents infinite

    public override bool deserialize_property (string property_name,
                                               out Value value,
                                               ParamSpec pspec,
                                               Json.Node property_node) {
        if (property_name == "time") {
            value = Value (typeof (GLib.DateTime));
            var result = new GLib.DateTime.from_iso8601 (property_node.get_string (), new GLib.TimeZone.local ());
            value.set_boxed (result);
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}

public class Valash.ProxyData : GLib.Object, Json.Serializable {
    public string[]                     all             { get; set; }
    public Gee.ArrayList<HealthHistory> history         { get; set;
        default = new Gee.ArrayList<HealthHistory> (); }
    public string                       id              { get; set; }
    public bool                         alive           { get; set; }
    public string                       dialer_proxy    { get; set; }
    public Json.Object                  extra           { get; set;
        default = new Json.Object (); }
    public bool                         hidden          { get; set; }
    public string                       icon            { get; set; }
    public string                       proxy_interface { get; set; }
    public bool                         mptcp           { get; set; }
    public string                       name            { get; set; }
    public string                       now             { get; set; }
    public int                          routing_mark    { get; set; }
    public bool                         smux            { get; set; }
    public string                       test_url        { get; set; }
    public bool                         tfo             { get; set; }
    public string                       proxy_type      { get; set; } // Name Conflict, type => proxy_type
    public bool                         udp             { get; set; }
    public bool                         uot             { get; set; }
    public bool                         xudp            { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        if (name == "type")
            return get_class ().find_property ("proxy_type");
        return get_class ().find_property (camel_to_kebab (name));
    }

    public override bool deserialize_property (string property_name,
                                               out Value value,
                                               ParamSpec pspec,
                                               Json.Node property_node) {
        if (property_name == "history") {
            value = Value (typeof (Gee.ArrayList));
            var result = new Gee.ArrayList<HealthHistory> ();

            var arr = property_node.get_array ();
            for (int i = 0; i < arr.get_length (); i++) {
                var node = arr.get_element (i);
                var data = (HealthHistory) Json.gobject_deserialize (typeof (HealthHistory), node);
                result.add (data);
            }
            value.set_object (result);
            return true;
        } else if (property_name == "extra") {
            value = Value (typeof (Json.Object));
            var obj = property_node.get_object ();
            value.set_boxed (obj ?? new Json.Object ());
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}

public class Valash.SubscriptionInfo : GLib.Object, Json.Serializable {
    public double          upload   { get; set; }
    public double          download { get; set; }
    public double          total    { get; set; }
    public GLib.DateTime?  expire   { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        return get_class ().find_property (name.down ());
    }

    public override bool deserialize_property (string property_name,
                                               out Value value,
                                               ParamSpec pspec,
                                               Json.Node property_node) {
        if (property_name == "expire") {
            value = Value (typeof (GLib.DateTime));
            var unix_time = property_node.get_int ();
            if (unix_time == 0) {
                value.set_boxed (null);
            } else {
                var result = new GLib.DateTime.from_unix_utc (unix_time);
                value.set_boxed (result);
            }
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}

public class Valash.ProxyProviderData : GLib.Object, Json.Serializable {
    public SubscriptionInfo?              subscription_info { get; set; }
    public Gee.HashMap<string, ProxyData> proxies           { get; set;
        default = new Gee.HashMap<string, ProxyData> (); }
    public string                         name              { get; set; }
    public string                         provider_type     { get; set; }
    public string                         vehicle_type      { get; set; }
    public string                         test_url          { get; set; }
    public string                         expected_status   { get; set; }
    public GLib.DateTime?                 updated_at        { get; set; }

    public override unowned ParamSpec? find_property (string name) {
        if (name == "type")
            return get_class ().find_property ("provider_type");
        return get_class ().find_property (camel_to_kebab (name));
    }

    public override bool deserialize_property (string property_name,
                                               out Value value,
                                               ParamSpec pspec,
                                               Json.Node property_node) {
        if (property_name == "proxies") {
            value = Value (typeof (Gee.HashMap));
            var result = new Gee.HashMap<string, ProxyData> ();

            var arr = property_node.get_array ();
            for (int i = 0; i < arr.get_length (); i++) {
                var node = arr.get_element (i);
                var data = (ProxyData) Json.gobject_deserialize (typeof (ProxyData), node);
                result.set (data.id, data);
            }
            value.set_object (result);
            return true;
        } else if (property_name == "updated-at") {
            value = Value (typeof (GLib.DateTime));
            var result = new GLib.DateTime.from_iso8601 (property_node.get_string (), new GLib.TimeZone.local ());
            value.set_boxed (result);
            return true;
        }
        return default_deserialize_property (property_name, out value, pspec, property_node);
    }
}
