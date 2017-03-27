defmodule Switchex.ResubscribeEventHandler do
  use GenEvent

  @name __MODULE__

  # Public API
  def subscribe(pid) do
    GenEvent.notify(@name, {:subscribe, pid})
  end

  def resubscribe do
    GenEvent.notify(@name, :resubscribe)
  end

  # Callbacks

  def start_link() do
    ret = GenEvent.start_link(name: @name)

    GenEvent.add_handler(@name, @name, [])

    ret
  end

  def handle_event({:subscribe, pid}, pids) do
    {:ok, [pid | pids]}
  end

  def handle_event(:resubscribe, pids) do
    pids |> Enum.each(&send(&1, :resubscribe))

    {:ok, pids}
  end
end
