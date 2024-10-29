defmodule ReflectOS.Firmware.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias ReflectOS.Kernel.Settings.System

  use Application

  @impl true
  def start(_type, _args) do
    # start the application with the configured viewport
    viewport_config =
      Application.get_env(:reflect_os_firmware, :viewport)
      |> Keyword.put(:size, System.viewport_size())

    children =
      [
        {DynamicSupervisor, name: ReflectOS.Firmware.LayoutManagerSupervisor},
        {Scenic, [viewport_config]}
      ] ++ children(Nerves.Runtime.mix_target())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReflectOS.Firmware.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  defp children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: ReflectOS.Worker.start_link(arg)
      # {ReflectOS.Worker, arg},
    ]
  end

  @dialyzer {:no_match, children: 1}
  defp children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: ReflectOS.Worker.start_link(arg)
      # {ReflectOS.Worker, arg},
    ]
  end
end
