defmodule Injector do
  @moduledoc """
  `Injector` is a entrypoint to CDI.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias Injector
      require Injector

      @options opts

      @before_compile __before_compile__()

      Module.register_attribute(__MODULE__, :inject, accumulate: true)
    end
  end

  defmacro inject(behaviour) do
    quote do
      @inject unquote(behaviour)
    end
  end

  def __on_definition__(env, _kind, _name, _args, _guards, _body) do
    resolve_injections(env.module)
  end

  defp resolve_injections(module) do
    injection_points = Module.get_attribute(module, :inject)
    Module.put_attribute(module, :imports, resolve_bindings(injection_points))
  end

  defp resolve_bindings(injection_points) do
    # TODO resolve points
    Enum.map(injection_points, fn _point -> nil end)
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
