defmodule MyspaceObject.Ipid do
  @moduledoc false

  require Logger
  import MyspaceObject.Utils

  # The context is the list of JSON-LD contexts that are used to interpret the IPID.
  # This is *not* correct at the moment, but it is a start.
  @context [
    "https://www.w3.org/ns/did/v1",
    "https://w3id.org/security/suites/ed25519-2020/v1"
  ]

  @registry :myspace_object_ipid_registry

  @enforce_keys [:id, :context, :created, :public_key]
  defstruct id: nil,
            context: @context,
            created: now(),
            updated: now(),
            public_key: nil

  @typedoc """
  The IPID is the object that is stored in the Myspace.
  """
  @type t :: %__MODULE__{
          id: binary(),
          context: list(),
          created: binary(),
          updated: binary(),
          public_key: binary()
        }

  @typep object :: MyspaceObject.t()

  @doc """
  Create a new IPID from a MyspaceObject.
  """
  @spec new(object) :: {:ok, t()}
  def new(object) when is_struct(object) do
    {:ok,
     %__MODULE__{
       id: did_gen!(object),
       context: @context,
       public_key: object.public_key.pem,
       created: object.created,
       updated: now()
     }}
  end

  @doc """
  Publish the IPID to IPFS. Returns :ok here, and then delivers the ipid
  back to the calling process, in a {:ipid_publish, MySpaceObject.ipid()} message.
  """
  @spec publish(t) :: :ok
  def publish(ipid) do
    Logger.debug("Publishing IPID #{ipid.id} to IPFS")
    start = Time.utc_now()

    key = did_fragment!(ipid.id)
    {:ok, add_result} = ExIpfs.add(json_encode_struct(ipid))

    ExIpfsIpns.publish(add_result.hash, key: key)
    Logger.debug("Publication of IPID finished in #{seconds_since(start)} seconds")
    :ok
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
  def did_gen!(object) when is_binary(object.id) and is_binary(object.ipns) do
    "did:ipid:" <> object.ipns <> "#" <> object.id
  end
end
