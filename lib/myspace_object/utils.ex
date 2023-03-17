defmodule MyspaceObject.Utils do
  @moduledoc false

  require Logger

  @doc """
  Creates a channel atom from an ID. Basically, it just prepends "channel@" to the ID.
  """
  @spec channel_atom(atom) :: atom()
  def channel_atom(id) do
    String.to_atom("channel@" <> Atom.to_string(id))
  end

  @doc """
  Fetches the contents of an IPLD link or dag.

  This might be a slow operation, so it is best to call it from a cast asyncronously.
  """
  @spec ipld_contents(MyspaceObject.Link.t() | binary()) :: {:ok, any}
  def ipld_contents(dag) when is_binary(dag) do
    {:ok, ipld_contents!(dag)}
  end

  def ipld_contents(link) when is_map(link) do
    {:ok, ipld_contents!(link./)}
  end

  @spec ipld_contents!(binary()) :: any
  def ipld_contents!(dag) when is_binary(dag) do
    start = Time.utc_now()
    {:ok, data} = ExIpfsIpld.get(dag)
    Logger.debug("Fetched IPLD contents for dag #{dag} in #{seconds_since(start)} seconds")
    data
  end

  @spec ipld_put!(any) :: ExIpfs.Link.t()
  def ipld_put!(data) when is_binary(data) do
    start = Time.utc_now()
    {:ok, dag} = ExIpfsIpld.put(data)
    Logger.debug("Put IPLD contents for dag #{dag} in #{seconds_since(start)} seconds")
    dag
  end

  def ipld_put!(data) when is_struct(data) do
    Map.from_struct(data) |> ipld_put!()
  end

  def ipld_put!(data) do
    Jason.encode!(data) |> ipld_put!()
  end

  @doc """
  Takes a struct and returns a map with the same keys and values.
  """
  @spec json_encode_struct(any) :: binary()
  def json_encode_struct(object) do
    Jason.encode!(Map.from_struct(object))
  end

  @doc """
  Returns the current time in ISO8601 format.
  """
  @spec now() :: binary
  def now() do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end

  @doc """
  Publishes the object to IPFS and returns the CID.
  """
  @spec publish_to_ipfs!(binary()) :: binary()
  def publish_to_ipfs!(public_key_pem) do
    start = Time.utc_now()
    {:ok, %ExIpfs.AddResult{hash: data}} = ExIpfs.add(public_key_pem)

    Logger.info(
      "Publication to IPFS returned #{inspect(data)} in #{seconds_since(start)} seconds."
    )

    data
  end

  @spec publish_to_ipfs(binary()) :: {:ok, binary()} | {:error, any}
  def publish_to_ipfs(data) do
    {:ok, publish_to_ipfs!(data)}
  end

  @doc """
  Returns the number of seconds since time. If finish is not given, the current time is used.
  """
  @spec seconds_since(Time.t()) :: integer
  def seconds_since(start) do
    Time.diff(Time.utc_now(), start)
  end
end
