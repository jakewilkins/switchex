defmodule Switchex.Responder do
  @name __MODULE__

  alias Switchex.Email

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), except: [process: 3]
      alias Switchex.Email

      def start_link() do
        pid = spawn_link(__MODULE__, :init, [])
        {:ok, pid}
      end

      def init() do
        :switchboard.subscribe(:new)
        loop()
      end

    end
  end

  def loop() do
    receive do
      {:new, {account, mbox}, attrs} ->
        email = fetch_email(account, mbox, attrs)
        process(account, mbox, email)
      {:test, account, mbox, message} ->
        process(account, mbox, message)
    end
    loop()
  end

  defmacro for_account(account, message, mmbox \\ :all, do: block) do
    quote do
      if unquote(mmbox) == :all do
        def process(account = unquote(account), mailbox, unquote(message)) do
          unquote(block)
        end
      else
        def process(account = unquote(account), mailbox = mmbox, unquote(message)) do
          unquote(block)
        end
      end
    end
  end

  defp fetch_email(account, mbox, attrs) do
    {:ok, mbid} = :switchboard_jmap.mailbox_name_to_id(account, mbox)

    message = Email.from_attrs(attrs, account, mbox)

    msid = :switchboard_jmap.message_id(mbid,  message.uid)
    state = :switchboard_jmap.state_by_account(account)

    {{"messages", fetched_message, _}, _state} = :switchboard_jmap.call({"getMessages", [{"ids", [ msid]},
      {"properties", ["subject", "from", "to", "textBody"]}], 8}, state)

    %{message | body: Keyword.get(Keyword.get(fetched_message, :list) |> hd, :textBody)}
  end

  def process(account, mailbox, email) do
    IO.puts "email received: #{mailbox}"
  end
  defoverridable [process: 3]

end
