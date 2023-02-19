defmodule MyspaceObject.Supervisor do
  @moduledoc """
  The MyspaceObject.Supervisor is a supervisor for a colletion of MyspaceObject.
  """
  use Supervisor

  @typep objects :: list(MyspaceObject.t())

  @spec start_link(objects, list()) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(objects, opts) do
    Supervisor.start_link(__MODULE__, objects, opts)
  end

  def init(objects) do
    workers = create_workers(objects)
    Supervisor.init(workers, strategy: :one_for_one)
  end

  @spec add(Supervisor.child_spec()) :: Supervisor.on_start()
  def add(worker) do
    Supervisor.start_child(__MODULE__, worker)
  end

  @spec new!(MyspaceObject.t()) :: Supervisor.child_spec()
  def new!(object) do
    child_spec(%{
      id: object.id,
      start: {MyspaceObject, :start_link, [object, name: object.id]}
    })
  end

  @spec create_workers([MyspaceObject.t()]) :: [Supervisor.child_spec()]
  defp create_workers(objects) do
    Enum.map(objects, &new!/1)
  end
end
