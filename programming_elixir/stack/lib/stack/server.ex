defmodule Stack.Server do
  use GenServer

  def start_link(stack) do
    GenServer.start_link(__MODULE__, stack, name: __MODULE__)
  end

  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  def push(value) do
    GenServer.cast(__MODULE__, { :push, value })
  end

  def handle_call(:pop, _from, stack) do
    case stack do
      [h | t] ->
        { :reply, h, t }
      [] ->
        System.halt(1)
    end
  end

  def handle_cast({ :push, value }, stack) do
    { :noreply, [ value | stack ] }
  end

  def terminate(reason, state) do
    IO.puts "TERMINATING: #{reason}"
    IO.puts "FINAL STATE: #{inspect(state)}"
  end
end
