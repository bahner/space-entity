defmodule MyspaceObject.Utils do
  @moduledoc false

  require Logger
  alias MyspaceIPFS.Key

  @doc """
  Fetches a key from the IPFS keychain. If the key is not found, it is created.
  """
  @spec get_or_create_ipfs_key!(binary()) :: binary()
  def get_or_create_ipfs_key!(id) when is_binary(id) do
    case get_ipfs_key_name(id) do
      {:error, :not_found} -> create_ipfs_key!(id)
      {:ok, key} -> key
    end
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
    {:ok, data} = MyspaceIPFS.Dag.get(dag)
    Logger.debug("Fetched IPLD contents for dag #{dag} in #{seconds_since(start)} seconds")
    data
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
    {:ok, %MyspaceIPFS.AddResult{hash: data}} = MyspaceIPFS.add(public_key_pem)

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

  # Following functions are private. I suspect they will just create
  # a lot of noise in the docs, so I'm hiding them.
  defp create_ipfs_key!(id) when is_binary(id) do
    {:ok, key} = Key.gen(id)
    key["Id"]
  end

  defp get_ipfs_key_name(id) when is_binary(id) do
    {:ok, %{"Keys" => keys}} = Key.list(l: true)

    case Enum.find(keys, fn key -> key["Name"] == id end) do
      nil -> {:error, :not_found}
      key -> {:ok, key["Id"]}
    end
  end
end
