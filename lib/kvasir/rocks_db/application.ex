defmodule Kvasir.RocksDB.Application do
  @moduledoc false
  use Application
  @spec stop(term) :: term

  def start(_type, _args), do: Kvasir.RocksDB.start_link()
end
