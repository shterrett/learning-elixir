defmodule Stack.Supervisor do
  use Supervisor

  def start_link(stack) do
    result = { :ok, sup } = Supervisor.start_link(__MODULE__, [stack])
    start_workers(sup, stack)
    result
  end

  def start_workers(sup, stack) do
    { :ok, stash } =
      Supervisor.start_child(sup, worker(Stack.Stash, [stack]))
    Supervisor.start_child(sup, supervisor(Stack.SubSupervisor, [stash]))
  end

  def init(_) do
    supervise [], strategy: :one_for_one
  end
end
