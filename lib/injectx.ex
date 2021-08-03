defmodule Injectx do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias Injectx
      import Injectx
      require Injectx

      import Injectx.Context,
        only: [
          inject_all: 1,
          inject_all: 2,
          dispatching: 4,
          dispatching: 5
        ]

      @imports []
      @options opts

      Module.register_attribute(__MODULE__, :inject, accumulate: true)

      @on_definition Injectx
    end
  end

  def __on_definition__(env, _kind, _name, _args, _guards, _body) do
    resolve_injections(env.module)
  end

  defmacro inject(module) when is_atom(module) do
    raise CompileError, description: "Option :as is required for injecting erlang modules"
  end

  defmacro inject(module = {:__aliases__, meta, aliases}) do
    inject_aliases(module, as: {:__aliases__, meta, [List.last(aliases)]})
  end

  defmacro inject(module, as) do
    inject_aliases(module, as)
  end

  defp inject_aliases({:__aliases__, _, aliases}, as) do
    aliases |> Module.concat() |> inject_aliases(as)
  end

  defp inject_aliases(module, as: as) do
    injection_point = Injectx.Context.inject(module)

    quote do
      alias unquote(injection_point), as: unquote(as)
    end
  end

  defp resolve_injections(module) do
    opts = Module.get_attribute(module, :options)
    injection_points = Module.get_attribute(module, :inject)
    Module.put_attribute(module, :imports, resolve_bindings(opts[:name], injection_points))
  end

  defp resolve_bindings(context_name, injection_points) do
    Enum.map(injection_points, fn injection_point ->
      Injectx.Context.inject(context_name, injection_point)
    end)
  end
end
