defmodule MyspaceObject.Link do
  @moduledoc """
  An object that can be stored in a Myspace.

  Receives message from IPFS and conserves it state as a dag and can state it config to the Myspace.
  """

  @enforce_keys [:/]

  defstruct [:/]

  @typedoc """
  This is the way DAG are represented in the IPLD.
  """
  @type t :: %__MODULE__{/: binary()}

  @doc """
  Returns the IPLD link to the object.
  """
  @spec new(binary()) :: t()
  def new(cid) when is_binary(cid) do
    %MyspaceObject.Link{/: "#{cid}"}
  end
end
