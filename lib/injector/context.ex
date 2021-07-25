defmodule Injector.Context do
  defstruct [:bindings]

  @type t :: t(Binding.t())
  @type t(binding) :: Enumerable.t(binding)

  defmodule Binding do
    defstruct [
      :behavior,
      :definitions,
      :default
    ]

    @type t() :: %__MODULE__{
            behavior: module(),
            definitions: list(),
            default: module()
          }
  end
end
