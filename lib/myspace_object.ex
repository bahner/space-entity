defmodule MyspaceObject do
  @moduledoc """
  An object that can be stored in a Myspace.

  Receives message from IPFS and conserves it state as a dag and can state it config to the Myspace.
  """

  use GenServer
  require Logger

  import MyspaceObject.Utils

  # This starts with an empty object, but this could very well contain lots of stuff.
  @dag "bafyreihpfkdvib5muloxlj5b3tgdwibjdcu3zdsuhyft33z7gtgnlzlkpm"

  @enforce_keys [:id, :created, :dag]
  defstruct id: nil,
            created: nil,
            dag: nil,
            ipns: "",
            object: %{},
            public_key: MyspaceObject.PublicKey.new("")

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
          created: binary(),
          dag: binary(),
          ipns: binary() | nil,
          object: map(),
          public_key: MyspaceObject.PublicKey.t()
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
    GenServer.start_link(__MODULE__, object, name: object.id)
  end

  def start_link(dag) when is_binary(dag) do
    object = new!(dag)
    GenServer.start_link(__MODULE__, object, name: object.id)
  end

  @spec start_link() :: :ignore | {:error, any} | {:ok, pid}
  def start_link() do
    object = new!()
    GenServer.start_link(__MODULE__, object, name: object.id)
  end

  @spec init(t()) :: {:ok, t()}
  def init(state) when is_map(state) do
    # Mark process as sensitive, then call tasks in parallel to populate the process stack.
    Process.flag(:sensitive, true)
    {:ok, private_key} = ExPublicKey.generate_key()
    Process.put(:process_ex_private_key, private_key)

    # Public and IPNS should always be generated.
    # IPNS will use the existing keypair if it exists.
    # Always update the object the from the DAG, as the DAG is the source of truth.
    tasks = [
      Task.async(fn -> ipns!(state.id) end),
      Task.async(fn -> public_key!(private_key) end)
    ]

    [ipns | [public_key]] = Enum.map(Task.yield_many(tasks), &get_task_result/1)

    {:ok,
     %__MODULE__{
       id: state.id,
       created: state.created,
       dag: state.dag,
       ipns: ipns,
       object: ipld_contents!(state.dag),
       public_key: public_key
     }}
  end

  # FIXME: this should probably be handled by a task supervisor or a rest supervisor.
  # This is a temporary solution to make sure that the object is published to IPNS.
  # But we don't really want toi have some sort of status that says everything has been populated.
  # As it stand the object will be ready eventually, but we don't know when.

  # Returns a skeleton object. It lacks a public key, but that is added later.
  # This is because the public key is derived from a secret key, which is not available at this point.
  @spec new!(binary()) :: t()
  def new!(dag \\ @dag) when is_binary(dag) do
    Logger.info("Creating new MyspaceObject from #{dag}")
    id = Nanoid.generate()

    %__MODULE__{
      id: String.to_atom(id),
      created: now(),
      dag: dag,
      ipns: "",
      object: ipld_contents!(dag),
      public_key: MyspaceObject.PublicKey.new!("")
    }
  end

  @spec new(binary()) :: {:ok, t()}
  def new(dag \\ @dag) when is_binary(dag) do
    {:ok, new!(dag)}
  end

  @spec sync_process :: :ok
  def sync_process() do
    GenServer.cast(self(), :sync_process)
  end

  # Getters
  def handle_call(:id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call(:dag, _from, state) do
    {:reply, state.dag, state}
  end

  def handle_call(:ipns, _from, state) do
    {:reply, state.ipns, state}
  end

  def handle_call(:object, _from, state) do
    {:reply, state.object, state}
  end

  def handle_call(:process_ex_public_key, _from, state) do
    {:reply, Process.get(:process_ex_public_key), state}
  end

  def handle_call(:process_public_key, _from, state) do
    {:reply, state.public_key, state}
  end

  # Methods
  def handle_call({:decrypt_public, message}, from, state) do
    if from == self() do
      {:reply, ExPublicKey.decrypt_public(message, state.public_key), state}
    else
      {:noreply, state}
    end
  end

  def handle_call({:sign, message}, from, state) do
    if from == self() do
      {:reply, ExPublicKey.sign(message, Process.get(:private_key)), state}
    else
      {:noreply, state}
    end
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

  def handle_cast(:sync_process, state) do
    %__MODULE__{
      state
      | public_key:
          MyspaceObject.PublicKey.new(
            Process.get(:process_public_key_pem),
            Process.get(:process_public_key_cid)
          ),
        ipns: Process.get(:ipns)
    }

    {:noreply, state}
  end

  # The following should block. It's a major operation on the object.
  @spec handle_call({:object_update, binary}, t()) :: {:noreply, t()}
  def handle_call({:object_update, dag}, state) do
    {:noreply, %{state | object: ipld_contents!(dag)}}
  end

  @spec handle_cast(any, any, any) :: {:reply, any, any}
  def handle_cast(msg, _from, state) do
    {:reply, msg, state}
  end

  def handle_info({_task, {:object_publish_reply, dag}}, state) do
    {:noreply, %{state | dag: dag}}
  end

  def handle_info({_task, {:dag_update, dag}}, state) do
    {:noreply, %{state | dag: dag}}
  end

  def handle_info(msg, state) do
    case msg do
      {:DOWN, _ref, :process, _pid, _reason} ->
        Logger.debug("DOWN: #{inspect(msg)}")
        {:noreply, state}
    end
  end

  defp ipns!(id) do
    get_or_create_ipfs_key!(Atom.to_string(id))
  end

  defp public_key!(private_key) do
    {:ok, pub} = ExPublicKey.public_key_from_private_key(private_key)
    {:ok, public_key_pem} = ExPublicKey.pem_encode(pub)

    # This operation might take time.
    public_key_cid = publish_to_ipfs!(public_key_pem)

    MyspaceObject.PublicKey.new!(public_key_cid, public_key_pem)
  end

  defp get_task_result(task) do
    {_, {:ok, result}} = task
    result
  end
end
