defmodule Injector.Context do
  alias Injector.Context

  @type behavior :: module()
  @type implementation :: module()
  @type implementations :: list()

  defstruct [
    :bindings,
    name: ApplicationContext
  ]

  @type t() :: %__MODULE__{
          name: atom() | ApplicationContext,
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
    defstruct [:module, :name, default: false]

    @type t() :: %__MODULE__{
            module: module(),
            name: atom() | nil,
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
        :ok
    end
  end

  @spec inject(behavior()) :: implementation()
  def inject(behavior), do: binding(ApplicationContext, behavior)

  @spec inject(atom(), behavior()) :: implementation()
  def inject(name, behavior), do: binding(name, behavior)

  @spec injects(behavior()) :: implementations()
  def injects(behavior), do: bindings(ApplicationContext, behavior)

  @spec injects(atom(), behavior()) :: implementations()
  def injects(name, behavior), do: bindings(name, behavior)

  defp binding(name, behavior) do
    Agent.get(name, fn bindings ->
      definition =
        bindings.bindings
        |> Enum.filter(fn binding -> binding.behavior == behavior end)
        |> Enum.flat_map(fn binding -> binding.definitions end)
        |> Enum.find(fn definition -> definition.default end)

      # TODO: Future use
      _module_name =
        if definition.name != nil do
          definition.name
          |> to_string()
          |> Code.eval_string()
          |> case do
            {m, []} -> m
            _ -> raise "Attempt to resolve Alias failed"
          end
        else
          behavior
          |> Module.split()
          |> List.last()
          |> Kernel.<>("Impl")
          |> Code.eval_string()
          |> case do
            {m, []} -> m
            _ -> raise "Attempt to resolve Alias failed"
          end
        end

      definition.module
    end)
  end

  defp bindings(name, behavior) do
    Agent.get(name, fn bindings ->
      bindings.bindings
      |> Enum.filter(fn binding -> binding.behavior == behavior end)
      |> Enum.flat_map(fn binding -> binding.definitions end)
      |> Enum.map(fn definition ->
        # TODO: Future use
        _name =
          if definition.name != nil do
            definition.name
            |> to_string()
            |> Code.eval_string()
            |> case do
              {m, []} -> m
              _ -> raise "Attempt to resolve Alias failed"
            end
          else
            behavior
            |> Module.split()
            |> List.last()
            |> Code.eval_string()
            |> case do
              {m, []} -> m
              _ -> raise "Attempt to resolve Alias failed"
            end
          end

        definition.module
      end)
    end)
  end
end
