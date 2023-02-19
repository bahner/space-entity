defmodule MyspaceObject.Application do
  @moduledoc """
  The MyspaceObject.Application is the main application for MyspaceObject.
  """
  use Application

  @object_worker %{
    id: MyspaceObject.Supervisor,
    start: {MyspaceObject.Supervisor, :start_link, [[], [name: MyspaceObject.Supervisor]]},
    type: :supervisor
  }

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [@object_worker]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
