defmodule Kvasir.RocksDB do
  @moduledoc ~S"""
  RocksDB agent cache.
  """
  @table :kvasir_rocksdb

  @spec open(term, charlist, Keyword.t()) :: :rocksdb.db_handle()
  def open(key, path, opts) do
    GenServer.call(__MODULE__, {:open, key, path, opts}, 60_000)
  end

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
  require Logger

  @doc false
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, [[]], [{:name, __MODULE__} | opts])

  @doc false
  @impl GenServer
  def init(_opts) do
    Process.flag(:trap_exit, true)

    table = :ets.new(@table, [:public, :set, :named_table, read_concurrency: true])
    {:ok, table}
  end

  @impl GenServer
  def handle_call({:open, key, path, opts}, _from, table) do
    current = lookup(key)

    ref =
      if is_nil(current) do
        Logger.info("Kvasir RocksDB: Open new DB<#{inspect(key)}> in #{inspect(path)}.")
        {:ok, r} = :rocksdb.open(path, opts)
        register(key, r)
        r
      else
        current
      end

    {:reply, ref, table}
  end

  @impl GenServer
  def terminate(reason, table) do
    table
    |> :ets.tab2list()
    |> Enum.each(fn {key, db} ->
      Logger.info("Kvasir RocksDB: Close DB<#{inspect(key)}> because #{inspect(reason)}.")
      :rocksdb.close(db)
    end)

    :ok
  end
end
