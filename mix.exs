defmodule ReflectOS.Firmware.MixProject do
  use Mix.Project

  @app :reflect_os_firmware

  @version Path.join(__DIR__, "VERSION")
           |> File.read!()
           |> String.trim()

  @all_targets [
    :rpi0,
    :rpi3a,
    :rpi3,
    :rpi4,
    :rpi5
  ]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.17",
      archives: [nerves_bootstrap: "~> 1.13"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host],
      aliases: []
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :observer, :runtime_tools],
      mod: {ReflectOS.Firmware.Application, [:logger, :scenic]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dialyxir
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Dependencies for all targets
      {:nerves, "~> 1.10", runtime: false},
      {:shoehorn, "~> 0.9.1"},
      {:ring_logger, "~> 0.11.0"},
      {:toolshed, "~> 0.4.0"},

      # Allow Nerves.Runtime on host to support development, testing and CI.
      # See config/host.exs for usage.
      {:nerves_runtime, "~> 0.13.0"},

      # Dependencies for all targets except :host
      {:nerves_pack, "~> 0.7.1", targets: @all_targets},

      # WiFi Wizard
      {:vintage_net_wizard, "~> 0.4", targets: @all_targets},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      {:reflect_os_rpi0, "~>  1.0.1", runtime: false, targets: :rpi0},
      {:reflect_os_rpi3a, "~>  1.0.1", runtime: false, targets: :rpi3a},
      {:reflect_os_rpi3, "~>  1.0.1", runtime: false, targets: :rpi3},
      {:reflect_os_rpi4, "~>  0.1.0", runtime: false, targets: :rpi4},
      {:reflect_os_rpi5, "~>  0.1.0", runtime: false, targets: :rpi5},

      # Scenic
      {:scenic, "~>  0.11.2"},
      {:scenic_driver_local, "~>  0.11"},
      {:scenic_fontawesome, "~>  0.1.0"},
      {:font_metrics,
       github: "jvantuyl/font_metrics", branch: "infinite_wrap_fix/1", override: true},

      # Override until v1.0.0 is released
      {:phoenix_live_view, "~> 1.0.0-rc.7", override: true}
    ] ++ reflect_os_deps(System.get_env("REFLECTOS_DEPS"))
  end

  def reflect_os_deps("local"),
    do: [
      {:reflect_os_kernel, path: "../kernel", override: true},
      {:reflect_os_core, path: "../core", override: true},
      {:reflect_os_console, path: "../console"}
    ]

  def reflect_os_deps(_),
    do: [
      {:reflect_os_kernel, "~> 0.10.0"},
      {:reflect_os_core, "~> 0.10.2"},
      {:reflect_os_console, "~> 0.10.3"}
    ]

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end
end
