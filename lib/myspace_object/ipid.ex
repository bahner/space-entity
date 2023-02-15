defmodule MyspaceObject.Ipid do
  @moduledoc false

  require Logger

  @context [
    "https://www.w3.org/ns/did/v1",
    "https://w3id.org/security/suites/ed25519-2020/v1"
  ]

  @enforce_keys [:id, :context, :created, :updated, :public_key]
  defstruct id: nil,
            context: @context,
            created: nil,
            updated: nil,
            public_key: %{/: nil},
            verification_method: nil

  # FIXME: created time is wrong. Should be the time of the first message.
  # @spec new(MyspaceObject.t()) :: MyspaceObject.ipid()
  @spec new(%{
          :created => %{:calendar => any, optional(any) => any},
          :id => atom,
          :ipns => any,
          :public_key => atom | %{:cid => any, optional(any) => any},
          optional(any) => any
        }) :: %MyspaceObject.Ipid{
          context: [<<_::224, _::_*160>>, ...],
          created: binary,
          id: <<_::64, _::_*8>>,
          public_key: %{/: any},
          updated: binary,
          verification_method: <<_::64, _::_*8>>
        }
  def new(object) when is_map(object) do
    id = Atom.to_string(object.id)
    did = "did:ipid:#{object.ipns}##{id}"
    created = object.created |> DateTime.to_iso8601()
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    public_key = object.public_key.cid

    %__MODULE__{
      id: did,
      context: @context,
      public_key: %{/: public_key},
      created: created,
      updated: now,
      verification_method: did
    }
  end

  @spec json(MyspaceObject.t()) :: binary()
  def json(object) do
    Jason.encode!(Map.from_struct(new(object)))
  end

  @spec publish(MyspaceObject.t()) :: {:ipid_publish, binary()}
  @doc """
  Publish the IPID to IPFS. Returns the IPFS CID of the IPID.
  """
  def publish(object) do
    Logger.debug("Publishing IPID for #{object.id}")
    {:ok, add_result} = MyspaceIPFS.add(json(object))
    cid = add_result.hash
    MyspaceIPFS.Name.publish(cid, key: object.id)
    {:ipid_publish, cid}
  end

  @spec put(MyspaceObject.t()) :: {:ipid_put, binary()}
  def put(object) do
    Logger.debug("Updating IPLD for #{object.id}")
    {:ok, link} = MyspaceIPFS.Dag.put(json(object))
    {:ipid_put, link./}
  end
end
