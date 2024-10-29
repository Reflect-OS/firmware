import Config

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Use shoehorn to start the main application. See the shoehorn
# library documentation for more control in ordering how OTP
# applications are started and handling failures.

config :shoehorn, init: [:nerves_runtime, :nerves_pack, :nerves_ssh]

# Erlinit can be configured without a rootfs_overlay. See
# https://github.com/nerves-project/erlinit/ for more information on
# configuring erlinit.

# Advance the system clock on devices without real-time clocks.
config :nerves, :erlinit,
  update_clock: true,
  hostname_pattern: "reflectos-%-.4s",
  pre_run_exec: "sh /pre-run-exec.sh"

# Configure the device for SSH IEx prompt access and firmware updates
#
# * See https://hexdocs.pm/nerves_ssh/readme.html for general SSH configuration
# * See https://hexdocs.pm/ssh_subsystem_fwup/readme.html for firmware updates

# You must provided a public key if you would like
# to be able to access your system via SSH
keys =
  System.user_home!()
  |> Path.join(".ssh/id_{rsa,ecdsa,ed25519}.pub")
  |> Path.wildcard()

if keys != [] do
  config :nerves_ssh,
    authorized_keys: Enum.map(keys, &File.read!/1)
end

# Configure the network using vintage_net
#
# Update regulatory_domain to your 2-letter country code E.g., "US"
#
# See https://github.com/nerves-networking/vintage_net for more information
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"wlan0",
     %{
       type: VintageNetWiFi
     }}
  ]

config :mdns_lite,
  # The `hosts` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For the official Nerves systems, this
  # is "nerves-<4 digit serial#>.local".  The `"nerves"` host causes mdns_lite
  # to advertise "nerves.local" for convenience. If more than one Nerves device
  # is on the network, it is recommended to delete "nerves" from the list
  # because otherwise any of the devices may respond to nerves.local leading to
  # unpredictable behavior.

  hosts: [:hostname, "nerves"],
  ttl: 120,
  instance_name: "ReflectOS",

  # Advertise the following services over mDNS.
  services: [
    %{
      protocol: "http",
      transport: "tcp",
      port: 80
    },
    %{
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "sftp-ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "epmd",
      transport: "tcp",
      port: 4369
    }
  ]

# Scenic Nerves Config
config :reflect_os_firmware, :viewport,
  name: :main_viewport,
  size: {1080, 1920},
  theme: :dark,
  default_scene: ReflectOS.Screen.Boot,
  drivers: [
    [
      module: Scenic.Driver.Local,
      position: [scaled: true, centered: true]
    ]
  ]

# ReflectOS Console - Production configuration
config :reflect_os_console, ReflectOS.ConsoleWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [
    # Enable IPv6 and bind on all interfaces.
    # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
    # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
    # for details about using IPv6 vs IPv4 and loopback vs public addresses.
    ip: {0, 0, 0, 0},
    port: 80
  ],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: "HEY05EB1dFVSu6KykKHuS4rQPQzSHv4F7mGVB/gnDLrIu75wE/ytBXy2TaL3A6RA",
  live_view: [signing_salt: "dx3+SiJX"],
  check_origin: false,
  render_errors: [
    formats: [html: ReflectOS.ConsoleWeb.ErrorHTML, json: ReflectOS.ConsoleWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ReflectOS.Console.PubSub,
  # Start the server since we're running in a release instead of through `mix`
  server: true,
  # Nerves root filesystem is read-only, so disable the code reloader
  code_reloader: false

config :vintage_net_wizard,
  dns_name: "reflectos-wifi.config",
  captive_portal: false,
  port: 90

# Kernel
config :reflect_os_kernel, :settings, data_directory: "/data"

# Nerves Time Zones
config :nerves_time_zones, data_dir: "/data/nerves_time_zones"

# Config fwup for target
config :nerves, :firmware, fwup_conf: "config/#{Mix.target()}/fwup.conf"

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
