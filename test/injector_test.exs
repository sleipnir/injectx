defmodule InjectorTest do
  use ExUnit.Case
  doctest Injector

  test "greets the world" do
    assert Injector.hello() == :world
  end
end
