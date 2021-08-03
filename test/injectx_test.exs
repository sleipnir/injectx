defmodule InjectxTest do
  use ExUnit.Case

  alias Injectx.Context

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
    defmodule TestInjectx do
      @moduledoc false
      use Injectx

      @implementation inject(TestBehaviour)

      def test(n), do: @implementation.test(n)
    end

    assert {:ok, 1} = TestInjectx.test(1)
  end

  test "inject all implementation of Behavior" do
    defmodule TestAllInjectx do
      @moduledoc false
      use Injectx

      @implementations inject_all(TestBehaviour)

      def test(n), do: Enum.map(@implementations, fn impl -> impl.test(n) end)
    end

    assert [{:ok, 1}, {:ok, 2}] = TestAllInjectx.test(1)
  end

  test "sync dispatching to all implementation of Behavior" do
    defmodule SyncTestAllImplementations do
      @moduledoc false
      use Injectx

      def test(n), do: dispatching(TestBehaviour, :test, [n], async: false)
    end

    assert [{:ok, InjectxTest.TestImpl1, {:ok, 1}}, {:ok, InjectxTest.TestImpl2, {:ok, 2}}] =
             SyncTestAllImplementations.test(1)
  end

  test "async dispatching to all implementation of Behavior" do
    defmodule AsyncTestAllImplementations do
      @moduledoc false
      use Injectx

      def test(n), do: dispatching(TestBehaviour, :test, [n], async: true)
    end

    assert [{:ok, _, {:ok, _}}, {:ok, _, {:ok, _}}] = AsyncTestAllImplementations.test(1)
  end
end
