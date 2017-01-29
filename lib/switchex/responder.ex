defmodule Switchex.Responder do

  alias Switchex.Email

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__) 
      alias Switchex.Email

      def start_link() do
        pid = spawn_link(__MODULE__, :init, [])
        {:ok, pid}
      end

      def init() do
        :switchboard.subscribe(:new)
        loop()
      end

      def loop() do
        receive do
          {:new, {account, mbox}, attrs} ->
            email = fetch_email(account, mbox, attrs)
            apply(__MODULE__, :process, [account, mbox, email])
          :info -> 
            IO.puts "we're here alright!"
        end
        loop()
      end

    end
  end

  defmacro for_account(account, use: func) do
    quote do
      def process(account = unquote(account), mailbox, message) do
        apply(unquote(func), [account, mailbox, message])
      end
    end
  end
  defmacro for_account(account, mailbox, use: func) do
    quote do
      def process(account = unquote(account), mailbox = unquote(mailbox), message) do
        apply(unquote(func), [account, mailbox, message])
      end
    end
  end

  def fetch_email(account, mbox, attrs) do
    {:ok, mbid} = :switchboard_jmap.mailbox_name_to_id(account, mbox)

    message = Email.from_attrs(attrs, account, mbox)

    msid = :switchboard_jmap.message_id(mbid,  message.uid)
    state = :switchboard_jmap.state_by_account(account)

    {{"messages", fetched_message, _}, _state} = :switchboard_jmap.call({"getMessages", [{"ids", [ msid]},
      {"properties", ["subject", "from", "to", "textBody"]}], 8}, state)

    %{message | body: Keyword.get(Keyword.get(fetched_message, :list) |> hd, :textBody)}
  end

end
