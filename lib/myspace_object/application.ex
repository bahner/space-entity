defmodule MyspaceObject.Application do
  @moduledoc false
  use Application

  @registry :myspace_object_registry
  @supervisor MyspaceObject.Supervisor

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      {Registry, [keys: :unique, name: @registry]},
      {@supervisor, name: @supervisor}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
