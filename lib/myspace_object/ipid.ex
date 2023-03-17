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
            public_key: ExIpfs.Link.new("")

  @typedoc """
  The IPID is the object that is stored in the Myspace.
  """
  @type t :: %__MODULE__{
          id: binary(),
          context: list(),
          created: binary(),
          updated: binary(),
          public_key: ExIpfs.Link.t()
        }

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start(__MODULE__, %{}, name: __MODULE__)

  @spec init(map) :: {:ok, nil}
  def init(state), do: {:ok, state}

  # @spec get!(binary()) :: t()
  # def get!(id) do
  #   data = ExIpfs.get(id)
  #   data
  #   # data = Jason.decode!("#{data}")

  #   # %__MODULE__{
  #   #   id: data.id,
  #   #   context: data["@context"],
  #   #   public_key: data.public_key,
  #   #   created: data.created,
  #   #   updated: data.updated
  #   # }
  # end

  @spec new!(MyspaceObject.t()) :: t()
  def new!(object) when is_map(object) do
    %__MODULE__{
      id: did_gen!(object),
      context: @context,
      public_key: ExIpfs.Link.new(object.public_key.cid),
      created: object.created,
      updated: now()
    }
  end

  @spec new(MyspaceObject.t()) :: {:ok, t()}
  def new(object) when is_map(object) do
    {:ok, new!(object)}
  end

  @doc """
  Publish the IPID to IPFS. Returns :ok here, and then delivers the ipid
  back to the calling process, in a {:ipid_publish, MySpaceObject.ipid()} message.
  """
  @spec publish(MyspaceObject.t()) :: :ok
  def publish(object) do
    # This is a pipeline. Send it to add, which will then pass it to publish.
    # ipid_add wll never need to be called directly. Use ExIpfs.add directly
    # for that.
    GenServer.cast(__MODULE__, {:ipid_publish_add, object})
    :ok
  end

  @spec handle_cast(any, any, any) :: {:noreply, any}
  @doc """
  Publish the IPID to IPFS. Returns the IPFS CID of the IPID.
  """
  def handle_cast({:ipid_publish_add, object}, _from, state) do
    Task.async(fn -> ipid_publish_add(object) end)
    {:noreply, state}
  end

  def handle_info({:ipid_publish_add_reply, {cid, ipid}}, state) do
    Task.async(fn -> ipid_publish({cid, ipid}) end)
    {:noreply, state}
  end

  @doc """
  Extract the fragment from the IPID. This is the NanoID.

  This function has a high concentration of sugar.
  """
  @spec did_fragment!(binary()) :: binary()
  def did_fragment!(did) do
    {_, fragment} = did_parse!(did)
    fragment
  end

  @doc """
  Split the IPID into its constituent parts.
  did:ipid:ipns#fragment. Returns a tuple of {ipns, fragment},
  eg {"Qm...", "NanoID"}

  Obiously "did:ipid" is ignored.
  """
  @spec did_parse!(binary()) :: {binary(), binary()}
  def did_parse!(ipid) do
    [did, fragment] = String.split(ipid, "#")
    [_, _, ipns] = String.split(did, ":")
    {ipns, fragment}
  end

  @doc """
  Generate an IPID from the IPNS name and the NanoID.
  """
  @spec did_gen!(MyspaceObject.t()) :: binary()
  def did_gen!(object) when is_atom(object.id) and is_binary(object.ipns) do
    "did:ipid:" <> object.ipns <> "#" <> Atom.to_string(object.id)
  end

  defp ipid_publish_add(ipid) do
    start = Time.utc_now()
    {:ok, cid} = ExIpfs.add(json_encode_struct(ipid))
    Logger.info("Publication of IPID yielding #{cid} finished in #{seconds_since(start)} seconds")
    {:ipid_publish_add_reply, {cid, ipid}}
  end

  defp ipid_publish({cid, ipid}) when is_binary(cid) do
    start = Time.utc_now()
    # Here we extract the fragment from the IPID, and use it to lookup up the
    # key. If it doesn't match the IPNS name hash then the id is useless.
    # That's supposed to be a good thing.
    ExIpfsIpns.publish(cid, key: did_fragment!(ipid.id))
    Logger.debug("Publication of IPID finished in #{seconds_since(start)} seconds")
    :ok
  end
end
