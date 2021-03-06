# Injectx

<!-- MDOC !-->

**Context Dependency Injection for Elixir**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `injectx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:injectx, "~> 0.1.0"}
  ]
end
```

`Injectx` module is a entrypoint to CDI.

## Usage:

Define your Behavior module:

```elixir
defmodule FooBehavior do
  @callback greetings(String.t()) :: String.t()
end
```

Implement it:

```elixir
defmodule FooImpl do
  @behavior FooBehavior

  @impl true
  def greetings(_name) do
    "Hello from FooImpl"
  end
end
```

Initialize Injectx Context on Application bootstrap:

```elixir
defmodule App do
  use Application

  alias Injectx.Context

  @impl true
  def start(_type, _args) do
    context = %Context{
      bindings: [
        %Context.Binding{
          behavior: FooBehavior,
          definitions: [
            %Context.BindingDefinition{module: FooImpl, default: true}
          ]
        }
      ]
    }

    Context.from(context)

    children = [
      ...
    ]

    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Use your behavior via Implementation resolved in runtime (using inject macro with same sintaxe of alias):

```elixir
defmodule Bar do
  use Injectx

  inject TestBehaviour

  def greetings(name), do: TestBehaviour.greetings(name)
end
```

### Or you can inject all implementations at once (using inject_all function):

```elixir
defmodule Caller do
  use Injectx

  # resolve all injection bindings for certain behavior
  @all inject_all(TestBehaviour)

....
  def call(), 
    do: Enum.each(@all, fn impl -> impl.greetings("Teddy") end)
end
```

## Dispatching

Injectx also provides the ability to dynamically dispatch your implementations.
For this it is only necessary to use the dispatcher function. Sync and Async are possible options:

```elixir
defmodule SomeBehaviour do
    @callback test(integer()) :: {:ok, integer()}
end

defmodule SomeImpl1 do
  @behaviour SomeBehaviour

  def test(1), do: {:ok, 1}
end

defmodule SomeImpl2 do
  @behaviour SomeBehaviour

  def test(1), do: {:ok, 2}
end

... bootstrap
  @impl true
  def start(_type, _args) do
    context = %Context{
      bindings: [
        %Context.Binding{
          behavior: SomeBehaviour,
          definitions: [
            %Context.BindingDefinition{module: SomeImpl1, default: true},
            %Context.BindingDefinition{module: SomeImpl2}
          ]
        }
      ]
    }

    Context.from(context)
    ....
  end

...write some client module...

defmodule SomeClientModule do
  use Injectx

  def call(arg), do: dispatching(TestBehaviour, :test, [arg], async: true)
   
end

...then call it `iex -S mix`

iex(1)> SomeClientModule.call(1)
[{:ok, InjectxTest.TestImpl2, {:ok, 2}}, {:ok, InjectxTest.TestImpl1, {:ok, 1}}]
```
