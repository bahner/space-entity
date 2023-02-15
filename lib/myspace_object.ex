defmodule MyspaceObject do
  @moduledoc """
  An object that can be stored in a Myspace.

  Receives message from IPFS and conserves it state as a dag and can state it config to the Myspace.
  """

  use GenServer

  require Logger

  alias MyspaceIPFS.Key
  alias MyspaceObject.Ipid

  # This starts with an empty object, but this could very well contain lots of stuff.
  @dag "bafyreihpfkdvib5muloxlj5b3tgdwibjdcu3zdsuhyft33z7gtgnlzlkpm"

  @enforce_keys [:id, :created, :dag, :ipns, :object]
  defstruct id: nil,
            created: DateTime.utc_now(),
            dag: @dag,
            ipns: nil,
            object: %{},
            public_key: %{
              pem: nil,
              cid: nil
            },
            ipid: %{
              cid: nil,
              dag: nil
            }

  @typedoc """
  The MyspaceObject is created with an atom as its name.

  This name, the MyspaceID or `myid`, is used to name the object locally.
  The dag is the IPFS hash of the object.
  The public key is the public key of the object, as derived from the IPNS.
  As such the IPNS name and the public key are the same, but the public_key is added here for quick local (trusted) lookup.
  The reason for doing it this way is that it is immediately available, where as publication to IPNS can take minutes,
  especially the first time.

  The default dag is `bafyreihpfkdvib5muloxlj5b3tgdwibjdcu3zdsuhyft33z7gtgnlzlkpm` which is the IPFS hash of an empty object.
  """

  @type t :: %__MODULE__{
          id: atom(),
          created: DateTime.t(),
          dag: binary(),
          ipns: binary() | nil,
          public_key:
            %{
              pem: binary(),
              cid: binary()
            }
            | nil,
          object: map(),
          ipid: %{
            cid: binary() | nil,
            dag: binary() | nil
          }
        }

  @typedoc """
  The IPID is the object that is stored in the Myspace.
  """
  @type ipid :: %{
          id: binary(),
          context: list(),
          created: binary(),
          updated: binary(),
          public_key: %{/: binary()},
          verification_method: binary()
        }
  @doc """
  Recreate a MyspaceObject from a map or a dag. When a map is given, it is assumed that the map is a valid MyspaceObject.
  When a dag is given, it is assumed that the dag is a valid IPLD object.

  When an object is passed a new keypair is generated and the public key is added to the object.

  If no parameter is given, a new default MyspaceObject is created.
  """
  @spec start_link(MyspaceObject.t() | binary()) ::
          :ignore | {:error, any} | {:ok, pid}

  def start_link(object) when is_map(object) do
    GenServer.start_link(__MODULE__, object, name: object.id)
  end

  def start_link(dag) when is_binary(dag) do
    object = new(dag)
    GenServer.start_link(__MODULE__, object, name: object.id)
  end

  @spec start_link() :: :ignore | {:error, any} | {:ok, pid}
  def start_link() do
    object = new()
    GenServer.start_link(__MODULE__, object, name: object.id)
  end

  @spec init(t()) :: {:ok, t()}
  def init(object) when is_map(object) do
    ipns = get_or_create_key!(Atom.to_string(object.id))
    object = %__MODULE__{object | ipns: ipns, public_key: generate_public_key()}
    GenServer.cast(self(), :ipid_publish)
    GenServer.cast(self(), :ipid_put)

    {:ok, %__MODULE__{object | object: ipld(object.dag)}}
  end

  # Returns a skeleton object. It lacks a public key, but that is added later.
  # This is because the public key is derived from a secret key, which is not available at this point.
  @spec new(binary() | atom()) :: t()
  def new(dag \\ @dag) when is_binary(dag) do
    id = String.to_atom(Nanoid.generate())

    %__MODULE__{
      id: id,
      created: DateTime.utc_now(),
      dag: dag,
      ipns: get_or_create_key!(Atom.to_string(id)),
      object: ipld(dag),
      public_key: nil
    }
  end

  # Getters
  def handle_call(:public_key, _from, state) do
    {:reply, state.public_key.key, state}
  end

  def handle_call(:public_key_cid!, _from, state) do
    {:reply, state.public_key.cid.hash, state}
  end

  def handle_call(:public_key_pem, _from, state) do
    {:reply, state.public_key.pem, state}
  end

  def handle_call(:ipns, _from, state) do
    {:reply, state.ipns, state}
  end

  # Methods
  def handle_call({:decrypt, message}, _from, state) do
    {:reply, ExPublicKey.decrypt_private(message, Process.get(:private_key)), state}
  end

  def handle_call({:sign, message}, _from, state) do
    {:reply, ExPublicKey.sign(message, Process.get(:private_key)), state}
  end

  def handle_call({:message, message, recipient}, _from, state) do
    # By using the recipient as the key, we can use the same key to encrypt the message and the signature.
    {:ok, encrypted_message} = ExPublicKey.encrypt_public(message, state.public_key)

    message = MyspaceObject.Message.new(encrypted_message, recipient, state.id)
    signed_message = ExPublicKey.sign(message, Process.get(:private_key))

    {:reply, signed_message, state}
  end

  def handle_call(msg, _from, state) do
    {:reply, msg, state}
  end

  # Casts
  # Don't wait for answers and how to handle them at this point.
  # Just assume it works.
  @spec handle_cast(:ipid_publish, MyspaceObject.t()) :: {:noreply, MyspaceObject.t()}
  def handle_cast(:ipid_publish, state) do
    Logger.debug("Publishing object #{inspect(state)}")
    Task.async(fn -> Ipid.publish(state) end)
    {:noreply, state}
  end

  @spec handle_cast(:ipid_put, MyspaceObject.t()) :: {:noreply, MyspaceObject.t()}
  def handle_cast(:ipid_put, state) do
    Logger.debug("Put object #{inspect(state)}")
    Task.async(fn -> Ipid.put(state) end)
    {:noreply, state}
  end

  @spec handle_cast(any, any, any) :: {:reply, any, any}
  def handle_cast(msg, _from, state) do
    {:reply, msg, state}
  end

  # Info
  def handle_info({_task, {:ipid_publish, cid}}, state) do
    Logger.debug("IPID published: #{inspect(cid)}")
    {:noreply, %{state | ipid: %{state.ipid | cid: cid}}}
  end

  def handle_info({_task, {:ipid_put, dag}}, state) do
    Logger.debug("IPID put: #{inspect(dag)}")
    {:noreply, %{state | ipid: %{state.ipid | dag: dag}}}
  end

  def handle_info(msg, state) do
    case msg do
      {:DOWN, _ref, :process, _pid, _reason} ->
        Logger.debug("DOWN: #{inspect(msg)}")
        {:noreply, state}
    end
  end
  # Helpers
  defp get_or_create_key!(id) when is_binary(id) do
    case get_ipns_key(id) do
      {:error, :not_found} -> create_key!(id)
      {:ok, key} -> key
    end
  end

  defp create_key!(id) when is_binary(id) do
    {:ok, key} = Key.gen(id)
    key["Id"]
  end

  # Lookup the IPNS key for the given id.
  defp get_ipns_key(id) when is_binary(id) do
    {:ok, %{"Keys" => keys}} = Key.list(l: true)

    case Enum.find(keys, fn key -> key["Name"] == id end) do
      nil -> {:error, :not_found}
      key -> {:ok, key["Id"]}
    end
  end

  # Simply get the public key as a PEM. (For publication in IPNS)
  defp public_key_pem do
    {:ok, pub} = ExPublicKey.public_key_from_private_key(Process.get(:private_key))
    {:ok, public_key_pem} = ExPublicKey.pem_encode(pub)
    public_key_pem
  end

  # Get the CID of the public key. (For linking in IPLD)
  defp public_key_cid!(public_key_pem) do
    {:ok, result} = MyspaceIPFS.add(public_key_pem)
    Logger.debug("Public key CID: #{inspect(result.hash)}")
    result.hash
  end

  # Fetch the contents of the dag and decode it.
  defp ipld(dag) do
    {:ok, ipld} = MyspaceIPFS.Dag.get(dag)
    Logger.debug("IPLD: #{inspect(ipld)}")
    ipld
  end

  defp generate_public_key() do
    Process.flag(:sensitive, true)
    {:ok, priv} = ExPublicKey.generate_key()
    Process.put(:private_key, priv)
    {:ok, pub} = ExPublicKey.public_key_from_private_key(priv)
    Process.put(:public_key, pub)

    %{
      pem: public_key_pem(),
      cid: public_key_cid!(public_key_pem())
    }
  end
end
