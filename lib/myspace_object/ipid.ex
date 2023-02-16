defmodule MyspaceObject.Ipid do
  @moduledoc false

  use GenServer

  require Logger
  import MyspaceObject.Utils

  # The context is the list of JSON-LD contexts that are used to interpret the IPID.
  # This is *not* correct at the moment, but it is a start.
  @context [
    "https://www.w3.org/ns/did/v1",
    "https://w3id.org/security/suites/ed25519-2020/v1"
  ]

  @enforce_keys [:id, :context, :created, :public_key]
  defstruct id: nil,
            context: @context,
            created: now(),
            updated: now(),
            public_key: MyspaceObject.Link.new("")

  @typedoc """
  The IPID is the object that is stored in the Myspace.
  """
  @type t :: %__MODULE__{
          id: binary(),
          context: list(),
          created: binary(),
          updated: binary(),
          public_key: MyspaceObject.Link.t()
        }

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start(__MODULE__, %{}, name: __MODULE__)

  @spec init(map) :: {:ok, nil}
  def init(state), do: {:ok, state}

  @doc """
  Publish the IPID to IPFS. Returns :ok here, and then delivers the ipid
  back to the calling process, in a {:ipid_publish, MySpaceObject.ipid()} message.
  """
  @spec publish({MyspaceObject.t(), pid}) :: :ok
  def publish(object) do
    GenServer.call(__MODULE__, {:publish, object})
    :ok
  end

  # @spec new!(MyspaceObject.t()) :: t()
  @spec new!(MyspaceObject.t()) :: t()
  def new!(object) when is_map(object) do
    %__MODULE__{
      id: gen_did!(object),
      context: @context,
      public_key: MyspaceObject.Link.new(object.public_key.cid),
      created: object.created,
      updated: now()
    }
  end

  @spec new(MyspaceObject.t()) :: {:ok, t()}
  def new(object) when is_map(object) do
    {:ok, new!(object)}
  end

  @spec handle_cast(any, any, any) :: {:noreply, any}
  @doc """
  Publish the IPID to IPFS. Returns the IPFS CID of the IPID.
  """
  def handle_cast({:publish_ipid, object}, _from, state) do
    Task.async(fn -> ipid_add(object) end)
    {:noreply, state}
  end

  def handle_info({:ipid_add_reply, {cid, ipid}}, state) do
    Task.async(fn -> ipid_publish({cid, ipid}) end)
    {:noreply, state}
  end

  defp ipid_add(ipid) do
    start = Time.utc_now()
    {:ok, cid} = MyspaceIPFS.add(json(ipid))
    Logger.debug("Publication of IPID DAG finished in #{seconds_since(start)} seconds")
    {:ipid_add_reply, {cid, ipid}}
  end

  defp ipid_publish({cid, ipid}) when is_binary(cid) do
    start = Time.utc_now()
    # Here we extract the fragment from the IPID, and use it to lookup up the
    # key. If it doesn't match the IPNS name hash then the id is useless.
    # That's supposed to be a good thing.
    MyspaceIPFS.Name.publish(cid, key: fragment(ipid.id))
    Logger.debug("Publication of IPID finished in #{seconds_since(start)} seconds")
    :ok
  end

  defp json(object) do
    Jason.encode!(Map.from_struct(new!(object)))
  end

  defp fragment(ipid) do
    {_, fragment} = split_ipid(ipid)
    fragment
  end

  defp split_ipid(ipid) do
    [did, fragment] = String.split(ipid, "#")
    [_, _, id] = String.split(did, ":")
    {id, fragment}
  end

  defp gen_did!(object) when is_atom(object.id) and is_binary(object.ipns) do
    "did:ipid:" <> object.ipns <> "#" <> Atom.to_string(object.id)
  end
end
