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

```

Use your behavior via Implementation resolved in runtime:

```elixir
defmodule Bar do
  use Injector

  @inject FooBehavior

  def greetings(name), do: FooBehavior.greetings(name)
end
```

### Or in some point of your code:

```elixir
# resolve all bindings for certain behavior
implementations = Injector.Context.bindings('test', FooBehavior)
```