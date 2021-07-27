# Injector

<!-- MDOC !-->

**Context Dependency Injection for Elixir**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `injector` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:injector, "~> 0.1.0"}
  ]
end
```

`Injector` module is a entrypoint to CDI.

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

Initialize Injector Context on Application bootstrap:

```elixir
defmodule App do
  use Application

  alias Injector.Context

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

Use your behavior via Implementation resolved in runtime:

```elixir
defmodule Bar do
  use Injector

  @foo_behaviour inject(TestBehaviour)

  def greetings(name), do: @foo_behaviour.greetings(name)
end
```

### Or you can inject all implementations at once:

```elixir
defmodule Caller do
  use Injector

  # resolve all injection bindings for certain behavior
  @foo_behaviours inject_all(TestBehaviour)

....
  def call(), 
    do: Enum.each(@foo_behaviours, fn impl -> impl.greetings("Teddy") end)
end
```

### Dispatching

Injector also provides the ability to dynamically dispatch your implementations.
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
  use Injector

  def call(arg), do: dispatching(TestBehaviour, :test, [arg], async: true)
   
end

...then call it `iex -S mix`

iex(1)> SomeClientModule.call(1)
[{:ok, InjectorTest.TestImpl2, {:ok, 2}}, {:ok, InjectorTest.TestImpl1, {:ok, 1}}]
```
