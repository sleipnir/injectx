defmodule Support.TestBehaviour do
  @moduledoc false
  @callback test(integer()) :: {:ok, integer()}
end

defmodule Support.TestImpl1 do
  @moduledoc false
  @behaviour TestBehaviour

  def test(1), do: {:ok, 1}
end

defmodule Support.TestInjector do
  @moduledoc false
  use Injector

  @inject TestBehaviour

  def test(n), do: TestBehaviour.test(n)
end
