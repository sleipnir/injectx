defmodule TestBehaviour do
  @moduledoc false
  @callback test(integer()) :: {:ok, integer()}
end

defmodule TestImpl1 do
  @moduledoc false
  @behaviour TestBehaviour

  def test(1), do: {:ok, 1}
end

defmodule TestInjector do
  @moduledoc false
  use Injector

  inject(TestBehaviour)

  def test(n), do: TestBehaviour.test(n)
end
