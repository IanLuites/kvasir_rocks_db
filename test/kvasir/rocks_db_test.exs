defmodule Kvasir.RocksDBTest do
  use ExUnit.Case
  doctest Kvasir.RocksDB

  test "greets the world" do
    assert Kvasir.RocksDB.hello() == :world
  end
end
