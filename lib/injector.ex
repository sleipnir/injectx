defmodule Injector do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias Injector
      require Injector

      import Injector.Context,
        only: [
          inject: 1,
          inject: 2,
          inject_all: 1,
          inject_all: 2,
          dispatching: 4,
          dispatching: 5
        ]

      @imports []
      @options opts

      Module.register_attribute(__MODULE__, :inject, accumulate: true)

      @on_definition Injector
    end
  end

  def __on_definition__(env, _kind, _name, _args, _guards, _body) do
    resolve_injections(env.module)
  end

  defp resolve_injections(module) do
    opts = Module.get_attribute(module, :options)
    injection_points = Module.get_attribute(module, :inject)
    Module.put_attribute(module, :imports, resolve_bindings(opts[:name], injection_points))
  end

  defp resolve_bindings(context_name, injection_points) do
    Enum.map(injection_points, fn injection_point ->
      Injector.Context.inject(context_name, injection_point)
    end)
  end
end
