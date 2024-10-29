# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :scenic, :assets, module: ReflectOS.Firmware.Assets

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1721045670"

# config :reflect_os_firmware, :default_layout, top_left: ReflectOS.Sections.DateTime

config :nerves_time_zones, default_time_zone: "America/New_York"

config :logger, :default_formatter,
  format: "[$level] $message $metadata\n",
  metadata: [:file, :line]

# ReflectOS Console
config :reflect_os_console, ReflectOS.ConsoleWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ReflectOS.ConsoleWeb.ErrorHTML, json: ReflectOS.ConsoleWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ReflectOS.Console.PubSub,
  live_view: [signing_salt: "dx3+SiJX"],
  secret_key_base: "hbVPCqM5m0KdHsWLwXWDrR16uNirtoeNvII/qUTSaVvP6NTq/jx9THcmggi3Zvyc",
  server: true

# Disable automatic TZ updates
config :tzdata, :autoupdate, :disabled

if Mix.env() == :prod do
  config :logger, level: :info
end

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end
