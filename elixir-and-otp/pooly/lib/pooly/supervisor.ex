defmodule Pooly.Supervisor do
  use Supervisor

  # API

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  # Callbacks

  def init(pools_config) do
    children = [
      supervisor(Pooly.PoolsSupervisor, []),
      worker(Pooly.Server, [pools_config])
    ]
    opts = [strategy: :one_for_all]

    supervise(children, opts)
  end
end
