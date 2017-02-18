defmodule Switchex.Supervisor do
  def start_link do
    ret = :switchboard_sup.start_link


    Application.get_env(:switchex, :logins, [])
    |> Enum.each(fn {hostname, username, password, mailboxes} ->
      Switchex.login(hostname, username, password, mailboxes)
    end)

    ret
  end
end
