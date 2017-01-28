defmodule Switchex.Responder do
  @name __MODULE__

  alias Switchex.Email

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      alias Switchex.Email
    end
  end

  def start_link() do
    pid = spawn_link(__MODULE__, :init, [])
    {:ok, pid}
  end

  def init([]) do
    :switchboard.subscribe(:new)
    loop()
  end

  def loop() do
    receive do
      {:new, {account, mbox}, attrs} ->
        email = fetch_email(account, mbox, attrs)
        process(account, mbox, email)
    end
  end

  def process(account, mailbox, email) do
    IO.puts "email received: #{mailbox}"
  end
  defoverridable [process: 3]

  defmacro for_account(account, mmbox \\ :all, do: block) do
    quote do
      if mmbox == :all do
        def process(account = unquote(account), mailbox, message) do
          unquote(block)
        end
      else
        def process(account = unquote(account), mailbox = unquote(mmbox), message) do
          unquote(block)
        end
      end
    end
  end

  defp fetch_email(account, mbox, attrs) do
    {:ok, mbid} = :switchboard_jmap.mailbox_name_to_id(account, mbox)

    message = Email.from_attrs(attrs)

    msid = :switchboard_jmap.message_id(mbid,  message.uid)
    state = :switchboard_jmap.state_by_account(account)

    {{"message", fetched_message}, _state} = :switchboard_jmap.call({"getMessages", [{"ids", [ msid]},
      {"properties", ["subject", "from", "to", "textBody"]}], 8}, state)

    %{message | body: Keyword.get(Keyword.get(fetched_message, :list) |> hd, :textBody)}
  end

end
