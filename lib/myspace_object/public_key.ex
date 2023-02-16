defmodule MyspaceObject.PublicKey do
  @moduledoc """
  An object that can be stored in a Myspace.

  Receives message from IPFS and conserves it state as a dag and can state it config to the Myspace.
  """

  @enforce_keys [:pem]

  defstruct cid: nil, pem: nil

  @typedoc """
  This is the way DAG are represented in the IPLD.
  """
  @type t :: %__MODULE__{
          cid: binary() | nil,
          pem: binary()
        }

  @doc """
  Returns the IPLD link to the object.
  """
  @spec new!(binary, binary | nil) :: t()
  def new!(pem, cid \\ nil) when is_binary(pem) do
    %__MODULE__{
      cid: cid,
      pem: pem
    }
  end

  @spec new(binary, binary | nil) :: {:ok, t()}
  def new(pem, cid \\ nil) when is_binary(pem) do
    {:ok, new!(pem, cid)}
  end
end
