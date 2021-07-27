defmodule InjectorTest do
  use ExUnit.Case

  alias Injector.Context

  defmodule TestBehaviour do
    @moduledoc false
    @callback test(integer()) :: {:ok, integer()}
  end

  defmodule TestImpl1 do
    @moduledoc false
    @behaviour TestBehaviour

    def test(1), do: {:ok, 1}
  end

  defmodule TestImpl2 do
    @moduledoc false
    @behaviour TestBehaviour

    def test(1), do: {:ok, 2}
  end

  setup do
    definition = %Context{
      bindings: [
        %Context.Binding{
          behavior: TestBehaviour,
          definitions: [
            %Context.BindingDefinition{module: TestImpl1, default: true},
            %Context.BindingDefinition{module: TestImpl2}
          ]
        }
      ]
    }

    Context.from(definition)
  end

  test "inject the default implementation of Behavior" do
    defmodule TestInjector do
      @moduledoc false
      use Injector

      @implementation inject(TestBehaviour)

      def test(n), do: @implementation.test(n)
    end

    assert {:ok, 1} = TestInjector.test(1)
  end

  test "inject all implementation of Behavior" do
    defmodule TestAllInjector do
      @moduledoc false
      use Injector

      @implementations inject_all(TestBehaviour)

      def test(n), do: Enum.map(@implementations, fn impl -> impl.test(n) end)
    end

    assert [{:ok, 1}, {:ok, 2}] = TestAllInjector.test(1)
  end
end
