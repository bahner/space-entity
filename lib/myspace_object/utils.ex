defmodule MyspaceObject.Utils do
  @moduledoc false

  require Logger

  @typep api_error :: ExIpfs.Api.error()

  @doc """
  Takes a struct and returns a map with the same keys and values.
  """
  @spec json_encode_struct(struct) :: binary
  def json_encode_struct(struct) when is_struct(struct) do
    Jason.encode!(Map.from_struct(struct))
  end

  @doc """
  Returns the current time in ISO8601 format.
  """
  @spec now :: binary
  def now do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end

  @doc """
  Publishes data to IPFS and returns the CID.

  This function is a wrapper around `ExIpfs.add/1`, but is easy to use and is likely to be
  used frequently.
  """
  @spec publish(binary()) :: {:ok, binary} | api_error | :error
  def publish(data) when is_binary(data) do
    response = ExIpfs.add(data)

    case response do
      {:ok, %ExIpfs.AddResult{hash: cid}} -> {:ok, cid}
      {:error, error} -> {:error, error}
    end
  end

  @spec ipld_contents!(binary()) :: any | api_error
  def ipld_contents!(cid) when is_binary(cid) do
    case ExIpfsIpld.get(cid) do
      {:ok, data} -> data
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Returns the number of seconds since time. If finish is not given, the current time is used.
  """
  @spec seconds_since(Time.t()) :: integer
  def seconds_since(start) do
    Time.diff(Time.utc_now(), start)
  end
end
