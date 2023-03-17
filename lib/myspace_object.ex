defmodule MyspaceObject do
  @moduledoc """
  An object that can be stored in a Myspace.

  Receives message from IPFS and conserves it state as a dag and can state it config to the Myspace.
  """

  use GenServer
  require Logger

  import MyspaceObject.Utils
  alias MyspaceObject.PublicKey

  @registry :myspace_object_registry
  alias MyspaceObject.PublicKey
  # This starts with an empty object, but this could very well contain lots of stuff.
  @dag "bafyreihpfkdvib5muloxlj5b3tgdwibjdcu3zdsuhyft33z7gtgnlzlkpm"

  @enforce_keys [:id, :created, :dag, :object]
  defstruct id: nil,
            created: now(),
            updated: now(),
            dag: @dag,
            object: %{},
            ipns: nil,
            public_key: nil

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
          id: atom,
          created: binary,
          updated: binary,
          dag: binary,
          object: any,
          ipns: binary | nil,
          public_key: MyspaceObject.PublicKey.t() | nil
        }

  @doc """
  Recreate a MyspaceObject from a map or a dag. When a map is given, it is assumed that the map is a valid MyspaceObject.
  When a dag is given, it is assumed that the dag is a valid IPLD object.

  When an object is passed a new keypair is generated and the public key is added to the object.

  If no parameter is given, a new default MyspaceObject is created.
  """
  @spec start_link(t() | binary()) ::
          :ignore | {:error, any} | {:ok, pid}

  def start_link(object) when is_map(object) do
    Logger.info("Creating MyspaceObject #{inspect(object)}")
    via_tuple = {:via, Registry, {@registry, object.id}}
    GenServer.start_link(__MODULE__, object, name: via_tuple)
  end

  def start_link(dag) when is_binary(dag) do
    Logger.info("Creating MyspaceObject from dag #{inspect(dag)}")
    object = new!(dag)
    GenServer.start_link(__MODULE__, object, name: object.id)
  end

  @spec start_link() :: :ignore | {:error, any} | {:ok, pid}
  def start_link() do
    Logger.info("Creating default MyspaceObject")
    object = new!()
    GenServer.start_link(__MODULE__, object, name: object.id)
  end

  @spec init(t()) :: {:ok, t()}
  def init(state) when is_map(state) do
    # Mark process as sensitive, then call tasks in parallel to populate the process stack.
    Process.flag(:sensitive, true)

    {:ok, ex_private_key} = ExPublicKey.generate_key()
    Process.put(:process_ex_private_key, ex_private_key)

    {:ok, ex_public_key} = ExPublicKey.public_key_from_private_key(ex_private_key)
    {:ok, ex_public_key_pem} = ExPublicKey.pem_encode(ex_public_key)

    # Public and IPNS should always be generated or updated .
    # IPNS will use the existing keypair if it exists.
    # Always update the object the from the DAG, as the DAG is the source of truth.
    tasks = [
      Task.async(fn -> get_or_create_ipns_key(state.id) end),
      Task.async(fn -> PublicKey.new(ex_public_key_pem) end),
      Task.async(fn -> ExIpfsIpld.get(state.dag) end),
    ]

    [ipns | tail] = Enum.map(Task.yield_many(tasks), &unwrap_task/1)
    [public_key | [object]] = tail

    case object do
      {:ok, object} ->
        Logger.info("MyspaceObject #{inspect(state)} created")
        {:ok, %__MODULE__{state | ipns: ipns, public_key: public_key, object: object}}

      {:error, error} ->
        Logger.error("MyspaceObject #{inspect(state)} failed to create: #{inspect(error)}")
        {:stop, error}
    end
  end

  # FIXME: this should probably be handled by a task supervisor or a rest supervisor.
  # This is a temporary solution to make sure that the object is published to IPNS.
  # But we don't really want toi have some sort of status that says everything has been populated.
  # As it stand the object will be ready eventually, but we don't know when.

  # Returns a skeleton object. It lacks a public key, but that is added later.
  # This is because the public key is derived from a secret key, which is not available at this point.
  @spec new!(binary()) :: t()
  def new!(dag \\ @dag) when is_binary(dag) do
    # Logger.info("Creating new MyspaceObject from #{dag}")
    id = Nanoid.generate()
    {:ok, ipns} = get_or_create_ipns_key(id)
    {:ok, object} = ExIpfsIpld.get(dag)

    %__MODULE__{
      id: String.to_atom(id),
      created: now(),
      updated: now(),
      dag: dag,
      object: object,
      ipns: ipns.id,
      public_key: nil,
    }
  end

  @spec sign(atom | pid, binary()) :: {:ok, binary()} | {:error, any}
  def sign(id, message) do
    GenServer.call(id, {:sign, message})
  end

  # Getters
  @spec created(t()) :: binary()
  def created(object) do
    GenServer.call(object.id, :created)
  end

  @spec dag(t()) :: binary()
  def dag(object) do
    GenServer.call(object.id, :dag)
  end

  @spec ipns(t()) :: binary()
  def ipns(object) do
    GenServer.call(object.id, :ipns)
  end

  @spec ipid(t()) :: MyspaceObject.Ipid.t()
  def ipid(object) do
    GenServer.call(object.id, :ipid)
  end

  @spec object(t()) :: binary()
  def object(object) do
    GenServer.call(object.id, :object)
  end

  @spec public_key(t()) :: binary()
  def public_key(object) do
    GenServer.call(object.id, :public_key)
  end

  @spec state(t()) :: binary()
  def state(object) do
    GenServer.call(object.id, :state)
  end

  # Getters
  def handle_call(:created, _from, state) do
    {:reply, state.created, state}
  end

  def handle_call(:dag, _from, state) do
    {:reply, state.dag, state}
  end

  def handle_call(:id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call(:ipid, _from, state) do
    {:reply, MyspaceObject.Ipid.new!(state), state}
  end

  def handle_call(:ipns, _from, state) do
    {:reply, state.ipns, state}
  end

  def handle_call(:object, _from, state) do
    {:reply, state.object, state}
  end

  def handle_call(:public_key, _from, state) do
    {:reply, state.public_key, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  # Setters
  def handle_call({:object_update, dag}, _from, state) do
    {:noreply, %{state | object: ipld_contents!(dag)}}
  end

  # Methods
  def handle_call({:decrypt_public, message}, _from, state) do
    {:reply, ExPublicKey.decrypt_public(message, state.public_key), state}
  end

  def handle_call({:sign, message}, _from, state) do
    {:reply, ExPublicKey.sign(message, Process.get(:process_ex_private_key)), state}
  end

  def handle_call(msg, _from, state) do
    Logger.warn("Unhandled call: #{inspect(msg)}")
    {:reply, msg, state}
  end

  # Casts

  @spec handle_cast(any, any, any) :: {:reply, any, any}
  def handle_cast(msg, _from, state) do
    Logger.warn("Unhandled cast: #{inspect(msg)}")
    {:reply, msg, state}
  end

  def handle_info({:object_publish_reply, dag}, state) do
    {:noreply, %{state | dag: dag}}
  end

  def handle_info({:dag_update, dag}, state) do
    {:noreply, %{state | dag: dag}}
  end

  def handle_info({:myspace_ipfs_pubsub_channel_message, msg}, state) do
    IO.puts("MyspaceObject: IPFS pubsub channel message #{msg} received.")
    {:noreply, state}
  end

  def handle_info(msg, state) do
    case msg do
      {:DOWN, _ref, :process, _pid, _reason} ->
        Logger.debug("DOWN: #{inspect(msg)}")
        {:noreply, state}

      _ ->
        Logger.warning("Unhandled message: #{inspect(msg)}")
        {:noreply, state}
    end
  end

  defp unwrap_task(data) do
    case data do
      {_, {:ok, result}} -> result
    end
  end
end
