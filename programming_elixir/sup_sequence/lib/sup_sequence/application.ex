defmodule SupSequence.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    { :ok, _pid } = SupSequence.Supervisor.start_link(100)
  end
end
