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
        Switchex.ResubscribeEventHandler.subscribe(self)

        send(self, :resubscribe)
        loop()
      end

      def loop() do
        receive do
          {:new, {account, mbox}, attrs} ->
            email = fetch_email(account, mbox, attrs)
            apply(__MODULE__, :process, [account, mbox, email])
          :resubscribe -> :switchboard.subscribe(:new)
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
        unquote(func).(account, mailbox, message)
      end
    end
  end
  defmacro for_account(account, mailbox, use: func) do
    quote do
      def process(account = unquote(account), mailbox = unquote(mailbox), message) do
        unquote(func).(account, mailbox, message)
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

    {body, raw_body} = Keyword.get(fetched_message, :list)
                        |> hd()
                        |> get_body()
    %{message | body: body, raw: raw_body}
  end

  def get_body(message) do
    raw = message |> Keyword.get(:textBody)
    raw = case String.starts_with?(raw, "\r\n") do
      true -> raw |> String.replace("\r\n", "", global: false)
      false -> raw
    end

    if String.starts_with?(raw, "--") do
      boundary = raw |> String.split("\r\n") |> List.first |> String.replace("--", "", global: false)
      parsed = %MimeMail{body: {:raw, raw}, headers: [{:"content-type", {"multipart/mixed", %{boundary: boundary}}}]}
        |> MimeMail.decode_body

      {parsed, raw}
    else
      {raw, nil}
    end
  end
end
