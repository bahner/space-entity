defmodule MyspaceObject.Application do
  @moduledoc """
  The MyspaceObject.Application is the main application for MyspaceObject.
  """
  use Application

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid()} | {:ok, pid(), any}
  def start(_type, _args) do
    MyspaceObject.Supervisor.start_link()
  end
end
