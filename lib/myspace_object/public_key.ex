defmodule MyspaceObject.PublicKey do
  @moduledoc """
  An object that can be stored in a Myspace.

  Receives message from IPFS and conserves it state as a dag and can state it config to the Myspace.
  """

  @enforce_keys [:pem, :cid]

  defstruct cid: nil, pem: nil

  @typedoc """
  This is the way DAG are represented in the IPLD.
  """
  @type t :: %__MODULE__{
          cid: binary(),
          pem: binary()
        }

  @doc """
  Returns a new MyspaceObject.PublicKey struct. From a PEM encoded public key.
  """
  @spec new(binary) :: {:ok, t()}
  def new(pem) when is_binary(pem) do
    {:ok, %ExIpfs.AddResult{hash: cid}} = ExIpfs.add(pem)

    {:ok,
     %__MODULE__{
       cid: cid,
       pem: pem
     }}
  end
end
