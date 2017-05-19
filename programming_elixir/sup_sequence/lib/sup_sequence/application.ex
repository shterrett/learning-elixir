defmodule SupSequence.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, initial_number) do
    { :ok, _pid } = SupSequence.Supervisor.start_link(Application.get_env(:sup_sequence, :initial_number))
  end
end
