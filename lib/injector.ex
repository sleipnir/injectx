defmodule Injector do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias Injector
      require Injector

      @before_compile Injector

      @options opts

      Module.register_attribute(__MODULE__, :inject, accumulate: true)
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
    # TODO resolve points
    Enum.map(injection_points, fn injection_point ->
      Injector.Context.binding(context_name, injection_point)
    end)
  end

  defmacro __before_compile__(env) do
    imports = Module.get_attribute(env.module, :imports)

    for import <- imports do
      quote bind_quoted: [import: import] do
        alias import
      end
    end
  end
end
