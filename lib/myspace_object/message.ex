defmodule MyspaceObject.Message do
  @moduledoc """
  A message to be sent to a MyspaceObject.

  Returns a JSON string, which can be signed and sent as a message to a MyspaceObject.

  TODO:
  * Do lookup of public keys and delivery address. Could be local.
  * Sign the message.
  """

  import MyspaceObject.Utils

  @typedoc """
  The message is the object that is sent to the MyspaceObject. It will be pushed to
  IPLD and the resulting CID will be signed and sent to the MyspaceObject.
  """
  @type content :: %{
          from: binary(),
          to: binary(),
          created: binary(),
          message: binary()
        }

  @type t :: %{
          dag: binary(),
          signature: binary()
        }

  @doc """
  Create a new message to be sent to a MyspaceObject. Returns a JSON string.
  """
  @spec new!(binary(), binary(), binary()) :: binary()
  def new!(message, to, from) do
    %{
      to: to,
      from: from,
      created: now(),
      message: encrypt_message_to_public_key!(message, to)
    }
    |> Jason.encode!()
  end

  defp get_public_key!(messenger) do
    # So this is cheating. Get the key from the sender's vault.
    # Ekko, er du der?
    GenServer.call(String.to_atom(messenger), :process_public_key)
  end

  defp encrypt_message_to_public_key!(message, recipient) do
    public_key = get_public_key!(recipient)
    ExPublicKey.encrypt_public(message, public_key)
  end
end
