defmodule Explorer.Chain.Cache.BlockSumBaseFeeBurnt do
  @moduledoc """
  Cache for block sum minus burnt number.
  """

  @default_cache_period :timer.hours(2)

  use Explorer.Chain.MapCache,
    name: :block_sum_base_fee_burnt,
    key: :sum_base_fee_burnt,
    key: :async_task,
    global_ttl: cache_period(),
    ttl_check_interval: :timer.minutes(15),
    callback: &async_task_on_deletion(&1)

  require Logger

  alias Explorer.Chain

  defp handle_fallback(:sum_base_fee_burnt) do
    # This will get the task PID if one exists and launch a new task if not
    # See next `handle_fallback` definition
    get_async_task()

    {:return, Decimal.new(0)}
  end

  defp handle_fallback(:async_task) do
    # If this gets called it means an async task was requested, but none exists
    # so a new one needs to be launched
    {:ok, task} =
      Task.start(fn ->
        try do
          result = Chain.fetch_sum_coin_base_fee_burnt()

          set_sum_base_fee_burnt(result)
        rescue
          e ->
            Logger.debug([
              "Coudn't update address sum test #{inspect(e)}"
            ])
        end

        set_async_task(nil)
      end)

    {:update, task}
  end

  # By setting this as a `callback` an async task will be started each time the
  # `sum_base_fee_burnt` expires (unless there is one already running)
  defp async_task_on_deletion({:delete, _, :sum_base_fee_burnt}), do: get_async_task()

  defp async_task_on_deletion(_data), do: nil

  defp cache_period do
    "BASE_FEE_BURNT_CACHE_PERIOD"
    |> System.get_env("")
    |> Integer.parse()
    |> case do
      {integer, ""} -> :timer.seconds(integer)
      _ -> @default_cache_period
    end
  end
end

