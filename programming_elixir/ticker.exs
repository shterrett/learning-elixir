defmodule Ticker do
  @interval 2000
  @name :ticker

  def start do
    pid = spawn(__MODULE__, :generator, [[], []])
    :global.register_name(@name, pid)
  end

  def register(client_pid) do
    send :global.whereis_name(@name), { :register, client_pid }
  end

  def generator(sent, waiting)
    when length(waiting) == 0 and length(sent) > 0 do
      generator(waiting, Enum.reverse(sent))
  end

  def generator(sent, waiting) do
    receive do
      { :register, pid } ->
        IO.puts "registering #{inspect pid}"
        generator(sent, [ pid | waiting ])
    after
      @interval -> # timeout restarts every time a message is received
                   # so if :register is received, the timeout will not be on
                   # time
        IO.puts "tick"
        case waiting do
          [next_client | rest] ->
            send next_client, { :tick }
            generator([next_client | sent ], rest)
          [] ->
            generator(sent, waiting)
        end
    end
  end
end

defmodule Client do
  def start do
    pid = spawn(__MODULE__, :receiver, [])
    Ticker.register(pid)
  end

  def receiver do
    receive do
      { :tick } ->
        IO.puts "tock in client"
        receiver()
    end
  end
end
