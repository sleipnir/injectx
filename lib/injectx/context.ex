defmodule Injectx.Context do
  alias Injectx.Context
  require Logger

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

  @spec from(Context.t()) :: :ok
  def from(context) do
    case Agent.start_link(fn -> %{} end, name: context.name) do
      {:ok, _pid} ->
        Agent.get_and_update(context.name, fn state ->
          merge = Map.merge(state, %{bindings: context.bindings})
          {merge, merge}
        end)

      {:error, {:already_started, _pid}} ->
        Agent.get(context.name, fn state -> state end)
    end
  end

  @spec from_config() :: :ok | {:error, :not_found}
  def from_config() do
    context = Application.get_env(:injectx, Injectx, :context)
    from(context)
  end

  @spec inject(behavior()) :: implementation()
  def inject(behavior), do: binding(ApplicationContext, behavior)

  @spec inject(atom(), behavior()) :: implementation()
  def inject(name, behavior), do: binding(name, behavior)

  @spec inject_all(behavior()) :: implementations()
  def inject_all(behavior), do: bindings(ApplicationContext, behavior)

  @spec inject_all(atom(), behavior()) :: implementations()
  def inject_all(name, behavior), do: bindings(name, behavior)

  @spec dispatching(module(), atom(), list(), [{:async, boolean}]) ::
          [{:ok, module(), any()}] | [{:error, module(), any()}]
  def dispatching(behavior, function_name, args, async: false) when is_list(args) do
    implementations = bindings(ApplicationContext, behavior)
    run(implementations, function_name, args)
  end

  def dispatching(behavior, function_name, args, async: true) when is_list(args) do
    implementations = bindings(ApplicationContext, behavior)
    run_async(implementations, function_name, args)
  end

  @spec dispatching(atom(), module(), atom(), list(), [{:async, boolean}]) ::
          [{:ok, module(), any()}] | [{:error, module(), any()}]
  def dispatching(context, behavior, function_name, args, async: false)
      when is_list(args) do
    implementations = bindings(context, behavior)
    run(implementations, function_name, args)
  end

  def dispatching(context, behavior, function_name, args, async: true) when is_list(args) do
    implementations = bindings(context, behavior)
    run_async(implementations, function_name, args)
  end

  defp binding(name, behavior) do
    context =
      case Agent.start_link(fn -> %{} end, name: name) do
        {:ok, _pid} ->
          Agent.get_and_update(name, fn state ->
            if state == %{} do
              # fallback from config file
              context = Application.get_env(:injectx, Injectx, :context)
              merge = Map.merge(state, %{bindings: context.bindings})
              {merge, merge}
            else
              {state, state}
            end
          end)

        {:error, {:already_started, _pid}} ->
          Agent.get(name, fn state -> state end)
      end

    case context do
      nil ->
        Logger.error("Not found binds from context #{name}")

      _ ->
        definition =
          context.bindings
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
    end
  end

  defp bindings(name, behavior) do
    context =
      case Agent.start_link(fn -> %{} end, name: name) do
        {:ok, _pid} ->
          Agent.get_and_update(name, fn state ->
            if state == %{} do
              # fallback from config file
              context = Application.get_env(:injectx, Injectx, :context)
              merge = Map.merge(state, %{bindings: context.bindings})
              {merge, merge}
            else
              {state, state}
            end
          end)

        {:error, {:already_started, _pid}} ->
          Agent.get(name, fn bindings -> bindings end)
      end

    context.bindings
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
  end

  defp run(implementations, function_name, args, _opts \\ []) do
    Enum.map(implementations, fn impl ->
      try do
        result = apply(impl, function_name, args)
        {:ok, impl, result}
      rescue
        error -> {:error, impl, error}
      end
    end)
  end

  defp run_async(implementations, function_name, args, _opts \\ []) do
    tasks =
      Enum.reduce(implementations, [], fn impl, acc ->
        [
          Task.async(fn ->
            try do
              result = apply(impl, function_name, args)
              {:ok, impl, result}
            rescue
              error -> {:error, impl, error}
            end
          end)
          | acc
        ]
      end)

    Enum.map(tasks, &Task.await/1)
  end
end
