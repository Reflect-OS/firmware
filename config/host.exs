import Config

# Scenic Config

config :reflect_os_firmware, :viewport,
  name: :main_viewport,
  size: {1080, 1920},
  theme: :dark,
  default_scene: ReflectOS.Screen.Dashboard,
  drivers: [
    [
      module: Scenic.Driver.Local,
      position: [scaled: true],
      window: [title: "ReflectOS"],
      on_close: :stop_system
    ]
  ]

# CubDB config
config :reflect_os_firmware, :cubdb, directory: "./data/notifications"

# Kernel
config :reflect_os_kernel, :settings, data_directory: "./data"

# Nerves Time Zones
config :nerves_time_zones, data_dir: "./data/nerves_time_zones"

# Add configuration that is only needed when running on the host here.

config :nerves_runtime,
  kv_backend:
    {Nerves.Runtime.KVBackend.InMemory,
     contents: %{
       # The KV store on Nerves systems is typically read from UBoot-env, but
       # this allows us to use a pre-populated InMemory store when running on
       # host for development and testing.
       #
       # https://hexdocs.pm/nerves_runtime/readme.html#using-nerves_runtime-in-tests
       # https://hexdocs.pm/nerves_runtime/readme.html#nerves-system-and-firmware-metadata

       "nerves_fw_active" => "a",
       "a.nerves_fw_architecture" => "generic",
       "a.nerves_fw_description" => "N/A",
       "a.nerves_fw_platform" => "host",
       "a.nerves_fw_version" => "0.0.0"
     }}

# ReflectOS Console
config :reflect_os_console, ReflectOS.ConsoleWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: false,
  debug_errors: true

# ReflectOS console - for local development by referencing the package in a local folder
# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  reflect_os_console: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.10",
  reflect_os_console: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
