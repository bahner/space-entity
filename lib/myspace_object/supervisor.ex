defmodule MyspaceObject.Supervisor do
  @moduledoc false

  use DynamicSupervisor, restart: :transient

  @typep ipid :: MyspaceObject.t()
  @registry :myspace_object_registry

  @spec start_link(Init_args) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @spec init(any) :: :ignore | {:ok, DynamicSupervisor.sup_flags()}
  def init(_init_args) do
    args = [strategy: :one_for_one]
    DynamicSupervisor.init(args)
  end

  @spec start_ipid(ipid) :: DynamicSupervisor.on_start_child()
  def start_ipid(ipid) when is_struct(ipid) do
    ipid_spec = %{
      id: ipid.id,
      start: {MyspaceObject, :start_link, [ipid]}
    }

    DynamicSupervisor.start_child(__MODULE__, ipid_spec)
  end
end
