defmodule Kvasir.RocksDB.AgentCache do
  @moduledoc ~S"""
  RocksDB agent cache.
  """
  @behaviour Kvasir.Agent.Cache
  @type ref :: {:rocksdb.db_handle(), String.t()}

  def open_db(agent, partition, opts) do
    key = agent
    # {agent, partition}

    if is_nil(Kvasir.RocksDB.lookup(key)) do
      path = db(opts[:directory], agent, partition)
      path |> Path.dirname() |> File.mkdir_p!()

      compact = System.schedulers()

      {:ok, ref} =
        :rocksdb.open(path,
          max_background_compactions: compact,
          max_open_files: -1,
          create_if_missing: true,
          merge_operator: :erlang_merge_operator,
          # merge_operator: {:bitset_merge_operator, 8},
          keep_log_file_num: 1,
          db_log_dir: '/tmp/rocks',
          allow_concurrent_memtable_write: true,
          enable_write_thread_adaptive_yield: true,
          use_direct_reads: true
          # enable_pipelined_write: true
        )

      Kvasir.RocksDB.register(key, ref)
    end

    {:ok, self()}
  end

  @impl Kvasir.Agent.Cache
  def init(agent, partition, opts) do
    args = [agent, partition, opts]

    {:ok,
     %{
       id: :"cache#{partition}",
       start: {__MODULE__, :open_db, args}
     }}
  end

  @impl Kvasir.Agent.Cache
  @spec cache(any, any, any) :: {:ok, ref}
  def cache(agent, partition, id)

  def cache(agent, _partition, id) do
    key = agent
    {:ok, {Kvasir.RocksDB.lookup(key), to_string(id)}}
  end

  @merge_open :erlang.term_to_binary({:list_set, 0, true})
  @empty :erlang.term_to_binary([false])

  @impl Kvasir.Agent.Cache
  def track_command({cache, id}) do
    :rocksdb.merge(cache, id, @merge_open, [])
  end

  @impl Kvasir.Agent.Cache
  def save({cache, id}, data, offset) do
    state = [false, offset, data]
    payload = :erlang.term_to_binary(state)

    :rocksdb.put(cache, id, payload, [])
  end

  @impl Kvasir.Agent.Cache
  def load({cache, id}) do
    case :rocksdb.get(cache, id, []) do
      :not_found ->
        :rocksdb.put(cache, id, @empty, [])
        :no_previous_state

      {:ok, data} ->
        case :erlang.binary_to_term(data) do
          [false] -> :no_previous_state
          [false, offset, data] -> {:ok, offset, data}
          _ -> {:error, :corrupted_state}
        end

      err ->
        err
    end
  end

  @impl Kvasir.Agent.Cache
  def delete({cache, id}) do
    :rocksdb.delete(cache, id, [])
  end

  @spec db(String.t() | nil, module, non_neg_integer) :: charlist()
  defp db(directory, agent, partition)

  defp db(nil, agent, _partition) do
    path = agent |> Module.split() |> Enum.map(&Macro.underscore/1)
    # full = ["./cache" | path] ++ [to_string(partition)]
    full = ["./cache" | path]
    full |> Path.join() |> String.to_charlist()
  end

  defp db(dir, _agent, _partition) do
    # dir |> Path.join(to_string(partition)) |> String.to_charlist()
    String.to_charlist(dir)
  end
end
