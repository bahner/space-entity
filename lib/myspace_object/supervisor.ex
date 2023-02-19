defmodule MyspaceObject.Supervisor do
  @moduledoc """
  The MyspaceObject.Supervisor is a supervisor for a colletion of MyspaceObject.
  """
  use Supervisor
  import MyspaceObject.Utils, only: [create_channel_atom: 1]

  @spec start_link(keyword()) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # Adding an object requires a channel worker to be started as well.
  # This means that we need a custom add function, so we can start the channel worker.
  def init(:ok) do
    Supervisor.init([], strategy: :one_for_one)
  end

  @spec add([MyspaceObject.t()] | MyspaceObject.t()) :: Supervisor.on_start()
  def add(object) when is_struct(object) do
    Supervisor.start_child(__MODULE__, create_worker(object))
    Supervisor.start_child(MyspaceIPFS.PubSub.ChannelSupervisor, create_channel_worker(object))
  end

  def add(objects) when is_list(objects) do
    Enum.each(objects, &add/1)
  end

  @spec create_worker(MyspaceObject.t()) :: Supervisor.child_spec()
  defp create_worker(object) when is_struct(object) do
    %{
      id: object.id,
      start: {MyspaceObject, :start_link, [object]}
    }
  end

  @spec create_channel_worker(MyspaceObject.t()) :: Supervisor.child_spec()
  defp create_channel_worker(object) when is_struct(object) do
    channel_topic = Atom.to_string(object.id)
    channel_atom = create_channel_atom(object.id)
    channel = MyspaceIPFS.PubSub.Channel.new!(object.id, channel_topic)

    %{
      id: object.id,
      start: {MyspaceIPFS.PubSub.Channel, :start_link, [channel, [name: channel_atom]]}
    }
  end
end
