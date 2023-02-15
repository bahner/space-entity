defmodule MyspaceObjectTest do
  use ExUnit.Case
  doctest MyspaceObject

  test "greets the world" do
    assert MyspaceObject.hello() == :world
  end
end
