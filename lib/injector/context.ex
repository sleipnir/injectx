defmodule Injector.Context do
  alias Injector.Context

  @type behavior :: module()
  @type implementation :: module()
  @type implementations :: list()

  defstruct [:name, :bindings]

  @type t() :: %__MODULE__{
          name: atom(),
          bindings: list()
        }

  defmodule Binding do
    @type behavior :: module()

    defstruct [
      :behavior,
      :definitions
    ]

    @type t() :: %__MODULE__{
            behavior: behavior(),
            definitions: list()
          }
  end

  defmodule BindingDefinition do
    defstruct [:module, :alias, :default]

    @type t() :: %__MODULE__{
            module: module(),
            alias: atom() | nil,
            default: boolean() | false
          }
  end

  @spec from_config(atom()) :: :ok | {:error, :not_found}
  def from_config(_otp_app) do
    :ok
  end

  @spec from_definition(Context.t()) :: :ok
  def from_definition(context) do
    case Agent.start_link(fn -> %{} end, name: context.name) do
      {:ok, _pid} ->
        Agent.update(context.name, fn state -> Map.merge(state, %{bindings: context.bindings}) end)

      {:error, {:already_started, _pid}} ->
        nil
    end

    :ok
  end

  @spec binding(String.t(), behavior()) :: implementation()
  def binding(_name, _behavior) do
  end

  @spec bindings(String.t(), behavior()) :: implementations()
  def bindings(_name, _behavior) do
    []
  end
end
