defmodule Kvasir.RocksDB do
  @moduledoc ~S"""
  RocksDB agent cache.
  """
  @table :kvasir_rocksdb

  @doc false
  @spec register(term, :rocksdb.db_handle()) :: boolean
  def register(key, reference) do
    :ets.insert_new(@table, {key, reference})
  end

  @doc false
  @spec lookup(term) :: :rocksdb.db_handle() | nil
  def lookup(key) do
    case :ets.lookup(@table, key) do
      [{^key, ref}] -> ref
      _ -> nil
    end
  end

  # Manage Table

  use GenServer

  @doc false
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, [[]], opts)

  @doc false
  @impl GenServer
  def init(_opts) do
    table = :ets.new(@table, [:public, :set, :named_table, read_concurrency: true])
    {:ok, table}
  end
end
