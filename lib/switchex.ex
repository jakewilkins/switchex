defmodule Switchex do
  @moduledoc """
  Documentation for Switchex.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Switchex.hello
      :world

  """
  def login(hostname, username, password, mailboxes \\ ["INBOX"]) do
    :switchboard.add({:ssl, hostname, 993}, {:plain, username, password}, mailboxes)
  end
end
