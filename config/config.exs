import Config

config :injectx, Injectx,
  context: %{
    name: ApplicationContext,
    bindings: [
      %{
        behavior: InjectxTest.TestBehaviour,
        definitions: [
          %{module: InjectxTest.TestImpl1, default: true},
          %{module: InjectxTest.TestImpl2, default: false}
        ]
      }
    ]
  }
