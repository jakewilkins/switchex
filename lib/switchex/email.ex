defmodule Switchex.Email do
  import Keyword, only: [get: 2]

  defstruct([from: "", from_name: "", to: "", to_name: "", subject: "", uid: "",
             body: "", internal: %{}])

  def from_attrs(attrs, acc, mbox) do
    [{:address, from}] = get_in(attrs, [:envelope, :from])
    [{:address, to}] = get_in(attrs, [:envelope, :to])
    uid = get(attrs, :uid)

    %__MODULE__{from: get(from, :email), from_name: get(from, :name),
      to: get(to, :email), to_name: get(to, :name), uid: uid,
      subject: get_in(attrs, [:envelope, :subject]),
      internal: %{account: acc, mailbox: mbox}}
  end

end
