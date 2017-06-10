defmodule Pooly.PoolsSupervisor do
  use Supervisor

  # API

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Callbacks

  def init(_) do
    opts = [
      strategy: :one_for_one
    ]
    supervise([], opts)
  end
end
