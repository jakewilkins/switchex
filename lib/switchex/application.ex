defmodule Switchex.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Switchex.Worker.start_link(arg1, arg2, arg3)
      # worker(Switchex.Worker, [arg1, arg2, arg3]),
      supervisor(:switchboard_sup, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Switchex.Supervisor]
    started = Supervisor.start_link(children, opts)

    Application.get_env(:switchex, :logins, [])
    |> Enum.each(fn({hostname, username, password, mailboxes}) ->
      Switchex.login(hostname, username, password, mailboxes)
    end)

    started
  end
end
