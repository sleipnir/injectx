defmodule Injectx.Macro do
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
end
