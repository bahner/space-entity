defmodule MyspaceObject.Supervisor do
  @moduledoc """
  The MyspaceObject.Supervisor is a supervisor for a colletion of MyspaceObject.
  """
  use Supervisor

  @spec start_link(list(MyspaceObject.t()) | MyspaceObject.t()) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(objects) when is_list(objects) do
    Supervisor.start_link(__MODULE__, objects, name: __MODULE__)
  end

  def start_link(object) when is_map(object) do
    Supervisor.start_link(__MODULE__, [object], name: __MODULE__)
  end

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(objects) when is_list(objects) do
    children = create_children(objects)
    Supervisor.init(children, strategy: :one_for_one)
  end

  def init(:ok) do
    Supervisor.init([], strategy: :one_for_one)
  end

  @spec add(MyspaceObject.t()) :: :ok
  def add(object) do
    Enum.each(create_object_children(object), fn child ->
      Supervisor.start_child(__MODULE__, child)
    end)

    :ok
  end

  @spec create_object_children(MyspaceObject.t()) :: [Supervisor.child_spec()]
  defp create_object_children(object) do
    [
      %{
        id: object.id,
        start: {MyspaceObject, :start_link, [object]}
      },
      %{
        id: create_channel_atom(object.id),
        start: {MyspaceIPFS.PubSubChannel, :start_link, [object.id, Atom.to_string(object.id)]}
      }
    ]
  end

  @spec create_children(list(MyspaceObject.t())) :: list
  defp create_children(objects) do
    objects
    |> Enum.map(&create_object_children/1)
    |> List.flatten()
  end

  defp create_channel_atom(id) do
    String.to_atom("channel@" <> Atom.to_string(id))
  end
end
