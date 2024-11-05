# ReflectOS Firmware

## About

ReflectOS is the approachable, configurable, and extensible OS for your Raspberry Pi smart mirror project.  It is designed to allow anyone to easily install, customize, and enjoy a smart mirror/display - no coding or command line usage required!

This repo contains the system firmware which is flashed to a MicroSD card for your Raspberry Pi.  It is optimized to work with the [Vilros Magic Mirror v4](https://vilros.com/products/vilros-magic-mirror-v4), but you can build your own as well!  See more project ideas, information, and setup guides in the [official documentation](https://Reflect-OS.github.io/docs).

## Quick Start

1. Download the correct `.img` file for your Raspberry Pi from the [latest release](https://github.com/Reflect-OS/firmware/releases/latest).  See the [official documentation](https://Reflect-OS.github.io/downloads) for details
on compatibility.
2. Use the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) or [Balena Etcher](https://etcher.balena.io) to flash the firmware your MicroSD card.
3. Insert the MicroSD card into your Raspberry Pi, plug it into the screen, and power it up!
4. Follow the instructions on screen to connect to your wifi network and configure
your system.

For a more detailed guide and lots more information on ReflectOS, please checkout the [official documentation](https://Reflect-OS.github.io/docs).

## Quickstart using `fwup`

Users familiar with the [fwup](https://github.com/fwup-home/fwup?tab=readme-ov-file#overview) tool
will recognize that each release also contains `.fw` builds.  These can be used with `fwup` to install
and update ReflectOS on your MicroSD card.

For example, for a fresh install of ReflectOS on Raspberry Pi 3:

```bash
fwup -a -i ReflectOS-firmware-rpi3.fw -t complete
```

To update an existing installation with a new firmware (note the `-t upgrade` option):

```bash
fwup -a -i ReflectOS-firmware-rpi3.fw -t upgrade
```

## Contributing

Contributions are welcome for this project!  You can
[open an issue](https://github.com/Reflect-OS/firmware/issues) to report a bug or request
a feature enhancement.  Code contributions are also welcomed, and can be
submitted by forking this repository and creating a pull request.

If you are interested in building your own extensions for ReflectOS,
please see the documentation for the [ReflectOS Kernel](https://hexdocs.pm/reflect_os_kernel) library.

## Developing

ReflectOS is built on the amazing [Nerves Project](https://nerves-project.org), an open source
platform for building embedded system using Elixir.  See details below for getting started developing on the firmware.

### Requirements

The Nerves project maintains excellent documentation, and contains the basics of what
you'll need to get started developing ReflectOS.

You can find the instructions here in the [Official Nerves Docs](https://hexdocs.pm/nerves/installation.html).

ReflectOS uses the [Scenic](https://hexdocs.pm/scenic/overview_general.html) package for
rendering native UIs, and you'll likely need a few additional dependencies to get that running
locally.  You can find detailed instructions in the
[Scenic Docs](https://hexdocs.pm/scenic/install_dependencies.html).

Once you have all the dependencies for Nerves and Scenic installed, you can follow the
instructions below to get ReflectOS running locally.

### Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/supported-targets.html

### Getting Started

To start developing locally:
* Install dependencies with `mix deps.get`
* Run `iex -S mix` to start the application

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix burn`

### Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Elixir Slack #nerves channel: https://elixir-slack.community/
  * Elixir Discord #nerves channel: https://discord.gg/elixir
  * Source: https://github.com/nerves-project/nerves
