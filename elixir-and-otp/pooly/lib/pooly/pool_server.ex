defmodule Pooly.PoolServer do
  use GenServer
  import Supervisor.Spec

  defmodule State do
    defstruct pool_sup: nil,
              worker_sup: nil,
              size: nil,
              mfa: nil,
              workers: nil,
              monitors: nil,
              name: nil,
              overflow: nil,
              max_overflow: nil,
              waiting: nil
  end

  # API

  def start_link(sup, pool_config) do
    GenServer.start_link(__MODULE__, [sup, pool_config], name: name(pool_config[:name]))
  end

  # Callbacks

  def init([pool_sup, pool_config]) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    waiting = :queue.new
    state = %State{ pool_sup: pool_sup,
                    monitors: monitors,
                    size: pool_config[:size],
                    waiting: waiting,
                    overflow: 0
            }
    init(pool_config, state)
  end
  def init([{:mfa, mfa} | rest], state) do
    init(rest, %{state | mfa: mfa })
  end
  def init([{ :size, size } | rest], state) do
    init(rest, %{ state | size: size })
  end
  def init([{ :name, name } | rest], state) do
    init(rest, %{ state | name: name })
  end
  def init([{ :max_overflow, max_overflow } | rest ], state) do
    init(rest, %{ state | max_overflow: max_overflow })
  end
  def init([_ | rest], state) do
    init(rest, state)
  end
  def init([], state) do
    send(self(), :start_worker_supervisor)
    { :ok, state }
  end

  def handle_info(:start_worker_supervisor,
                  %{ pool_sup: pool_sup, name: name, mfa: mfa, size: size } = state) do
    { :ok, worker_sup } = Supervisor.start_child(pool_sup, supervisor_spec(name, mfa))
    workers = prepopulate(size, worker_sup)
    { :noreply, %{ state | worker_sup: worker_sup, workers: workers } }
  end
  def handle_info({:DOWN, ref, _, _, _}, %{ monitors: monitors, workers: workers } = state) do
    case :ets.match(monitors, { :"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        new_state = %{ state | workers: [pid | workers] }
        { :noreply, new_state }
      [[]] ->
        { :noreply, state }
    end
  end
  def handle_info({ :EXIT, pid, _reason }, %{ monitors: monitors } = state) do
    case :ets.lookup(monitors, pid) do
      [[pid, ref]] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = handle_worker_exit(pid, state)
        { :noreply, new_state }
      [[]] ->
        { :noreply, state }
    end
  end

  def handle_call({ :checkout, block }, { from_pid, _ref } = from, state) do
    %{ worker_sup: worker_sup,
       workers: workers,
       monitors: monitors,
       overflow: overflow,
       max_overflow: max_overflow,
       waiting: waiting
    } = state

    case workers do
      [worker | rest ] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, { worker, ref })
        { :reply, worker, %{ state | workers: rest } }
      [] when max_overflow > 0 and overflow < max_overflow ->
        { worker, ref } = new_worker(worker_sup)
        true = :ets.insert(monitors, { worker, ref })
        { :reply, worker, %{ state | overflow: overflow + 1 } }
      [] when block == true ->
        ref = Process.monitor(from_pid)
        waiting = :queue.in({ from, ref }, waiting)
        { :noreply, %{ state | waiting: waiting }, :infinity }
      [] ->
        { :reply, :full, state }
    end
  end
  def handle_call(:status, _from, %{ workers: workers, monitors: monitors } = state) do
    { :reply, { state_name(state),  length(workers), :ets.info(monitors, :size) }, state }
  end

  def handle_cast({ :checkin, worker_pid }, state) do
    state = handle_checkin(worker_pid, state)
    { :noreply, state }
  end

  # Private

  defp handle_checkin(pid, state) do
    %{ worker_sup: worker_sup,
       workers: workers,
       monitors: monitors,
       overflow: overflow,
       waiting: waiting
    } = state

    case :queue.out(waiting) do
      { { :value, { from, ref } }, left} ->
        true = :ets.insert(monitors, { pid, ref })
        GenServer.reply(from, pid)
        %{ state | waiting: left }
      { :empty, empty } when overflow > 0 ->
        :ok = dismiss_worker(worker_sup, pid)
        %{ state | waiting: empty, overflow: overflow - 1 }
      { :empty, empty } ->
        %{ state | waiting: empty, workers: [pid | workers], overflow: 0 }
    end
  end

  defp handle_worker_exit(_pid, state) do
    %{ worker_sup: worker_sup,
       workers: workers,
       monitors: monitors,
       overflow: overflow,
       waiting: waiting
    } = state

    case :queue.out(waiting) do
      { { :value, { from, ref } }, left } ->
        new_worker = new_worker(worker_sup)
        true = :ets.insert(monitors, { new_worker, ref })
        GenServer.reply(from, new_worker)
        %{ state | waiting: left }
      { :empty, empty } when overflow > 0 ->
        %{ state | overflow: overflow - 1, waiting: empty }
      { :empty, empty } ->
        workers = [new_worker(worker_sup) | workers]
        %{ state | workers: workers, waiting: empty }
    end
  end

  defp dismiss_worker(sup, pid) do
    true = Process.unlink(pid)
    Supervisor.terminate_child(sup, pid)
  end

  defp supervisor_spec(name, mfa) do
    opts = [id: name <> "WorkerSupervisor", restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [self(), mfa], opts)
  end

  defp prepopulate(size, sup) do
    prepopulate(size, sup, [])
  end
  defp prepopulate(size, _sup, workers) when size < 1 do
    workers
  end
  defp prepopulate(size, sup, workers) do
    prepopulate(size - 1, sup, [new_worker(sup) | workers])
  end

  defp new_worker(sup) do
    { :ok, worker } = Supervisor.start_child(sup, [[]])
    worker
  end

  def name(pool_name) do
    :"#{pool_name}Server"
  end

  defp state_name(%{ overflow: overflow, max_overflow: max_overflow }) do
    cond do
      overflow <= 0 -> :ready
      overflow > 0 and overflow < max_overflow -> :overflow
      overflow >= max_overflow -> :full
    end
  end
end
