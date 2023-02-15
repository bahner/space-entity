defmodule MyspaceObject.Message do
  @moduledoc """
  A message to be sent to a MyspaceObject.

  Returns a JSON string, which can be signed and sent as a message to a MyspaceObject.

  TODO:
  * Do lookup of public keys and delivery address. Could be local.
  * Sign the message.
  """

  @type t :: %{
          from: binary(),
          to: binary(),
          message: binary()
        }

  @spec new(binary(), binary(), binary()) :: binary()
  def new(message, to, from) do
    %{
      to: to,
      from: from,
      message: encrypt_message_to_public_key!(message, to)
    }
    |> Jason.encode!()
  end

  defp get_recipient_public_key!(recipient) do
    # So this is cheating. Get the key from the sender's vault.
    # Ekko, er du der?
    GenServer.call(String.to_atom(recipient), :public_key)
  end

  defp encrypt_message_to_public_key!(message, recipient) do
    public_key = get_recipient_public_key!(recipient)
    ExPublicKey.encrypt_public(message, public_key)
  end
end
