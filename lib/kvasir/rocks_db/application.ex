defmodule Kvasir.RocksDB.Application do
  @moduledoc false
  use Application
  alias Kvasir.RocksDB.Metrics
  @spec stop(term) :: term

  def start(_type, _args) do
    Metrics.create()
    Kvasir.RocksDB.start_link()
  end
end
