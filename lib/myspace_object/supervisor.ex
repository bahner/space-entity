defmodule MyspaceObject.Supervisor do
  @moduledoc """
  The MyspaceObject.Supervisor is a supervisor for a colletion of MyspaceObject.
  """
  use Supervisor

  @spec start_link(list(MyspaceObject.t())) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(objects \\ []) when is_list(objects) do
    Supervisor.start_link(__MODULE__, objects, name: __MODULE__)
  end

  def init(objects) do
    children = create_children(objects)

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec create_child(MyspaceObject.t()) :: Supervisor.child_spec()
  def create_child(object) do
    %{
      # NB the id is used as the name of the process, this might conflict with the actual process.
      id: object.id,
      start: {MyspaceObject, :start_link, [object]}
    }
  end

  @spec create_children(list(MyspaceObject.t())) :: list
  def create_children(objects) do
    objects
    |> Enum.map(&create_child/1)
  end
end
