defmodule Unique do
  def echo(token, pid) do
    send pid, token
  end

  def listen() do
    receive do
      msg ->
        IO.puts msg
        listen()
    end
  end

  def run() do
    spawn(Unique, :echo, ["houdini", self()])
    spawn(Unique, :echo, ["cat", self()])
    spawn(Unique, :echo, ["kitten", self()])
    listen()
  end
end

defmodule LinkMonitor do
  def receive_all() do
    receive do
      { :EXIT, _, _, _, msg } ->
        IO.puts(inspect msg)
      { :DOWN, _, _, _, msg } ->
        IO.puts(inspect msg)
      msg ->
        IO.puts(inspect msg)
        receive_all()
    end
  end

  def send_and_exit(pid) do
    send pid, "Remember me!"
    exit(0)
  end

  def send_and_die(pid) do
    send pid, "Remember me!"
    exit(:boom)
  end

  def wait_a_bit_1() do
    spawn_link LinkMonitor, :send_and_exit, [self()]
    :timer.sleep(500)
    receive_all()
  end

  def wait_a_bit_2() do
    spawn_link LinkMonitor, :send_and_die, [self()]
    :timer.sleep(500)
    receive_all()
  end

  def wait_a_bit_3() do
    spawn_monitor LinkMonitor, :send_and_exit, [self()]
    :timer.sleep(500)
    receive_all()
  end

  def wait_a_bit_4() do
    spawn_monitor LinkMonitor, :send_and_die, [self()]
    :timer.sleep(500)
    receive_all()
  end
end

defmodule ParallelMap do
  def pmap(collection, f) do
    me = self() # this is javascript nonsense; self will change in the function
                # in the spawn_link call
    collection
    |> Enum.map(fn (elem) ->
         spawn_link fn -> (send me, { self(), f.(elem) }) end
       end)
       |> Enum.map(fn (pid) ->
         receive do { ^pid, result } -> result end
       end)
  end
end

defmodule Fibonacci do
  def fib(scheduler) do
    send scheduler, { :ready, self }
    receive do
       { :fib, n, client } ->
         send client, { :answer, n, fib_calc(n), self }
         fib(scheduler)
      { :shutdown} ->
        exit(:normal)
    end
  end

  defp fib_calc(0), do: 0
  defp fib_calc(1), do: 1
  defp fib_calc(n), do: fib_calc(n - 1) + fib_calc(n - 2)

  def calculate(n) do
    to_process = List.duplicate(n, 20)
    Enum.each 1..10, fn num_processes ->
      { time, result } = :timer.tc(
        Scheduler, :run,
        [num_processes, Fibonacci, :fib, to_process]
      )

      if num_processes == 1 do
        IO.puts inspect result
        IO.puts "\n#   time (s) "
      end

      :io.format "~2B      ~.2f~n", [num_processes, time/1000000.0]
    end
  end
end

defmodule Scheduler do
  def run(num_processes, module, fun, to_calculate) do
    (1..num_processes)
    |> Enum.map(fn(_) -> spawn(module, fun, [self()]) end)
    |> schedule_processes(to_calculate, [])
  end

  defp schedule_processes(processes, queue, results) do
    receive do
      { :ready, pid } when length(queue) > 0 ->
        [ next | tail ] = queue
        send pid, { :fib, next, self }
        schedule_processes(processes, tail, results)

      { :ready, pid } ->
        send pid, { :shutdown }
        if length(processes) > 1 do
          schedule_processes(List.delete(processes, pid), queue, results)
        else
          Enum.sort(results, fn { n1, _ }, { n2, _ } -> n1 <= n2 end)
        end

      { :answer, number, result, _pid } ->
        schedule_processes(processes, queue, [{ number, result } | results])
    end
  end
end
