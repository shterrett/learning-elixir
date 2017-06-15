use Mix.Config

defmodule Blitzy.CLI do
  require Logger

  def main(args) do
    Application.get_env(:blitzy, :master_node)
    |> Node.start

    Application.get_env(:blitzy, :slave_nodes)
    |> Enum.map(&Node.connect(&1))

    args
    |> parse_args
    |> process_options(Enum.reverse [node() | Node.list])
  end

  defp parse_args(args) do
    OptionParser.parse(args, aliases: [n: :requests],
                       strict: [requests: :integer])
  end

  defp process_options(options, nodes) do
    case options do
      {[requests: n], [url], [] } ->
        do_requests(n, url, nodes)
      _ ->
        do_help()
    end
  end

  defp do_requests(n_requests, url, nodes) do
    Logger.info "Pummeling #{url} with #{n_requests} requests"

    total_nodes = Enum.count(nodes)
    req_per_node = div(n_requests, total_nodes)

    nodes
    |> IO.inspect
    |> Enum.flat_map(fn node ->
      1..req_per_node
      |> Enum.map(fn _ ->
        Task.Supervisor.async({Blitzy.TasksSupervisor, node},
                              Blitzy.Worker, :start, [url])
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results
  end

  defp parse_results(results) do
    {successes, _failures } =
      results
      |> Enum.partition(fn x ->
        case x do
          {:ok, _} -> true
          _ -> false
        end
      end)

    total_workers = Enum.count(results)
    total_success = Enum.count(successes)
    total_failure = total_workers - total_success

    data = Enum.map(successes, fn {:ok, time} -> time end)
    average_time = average(data)
    longest_time = Enum.max(data)
    shortest_time = Enum.min(data)

    IO.puts """
    Total workers: #{total_workers}
    Successful reqs: #{total_success}
    Failed reqs: #{total_failure}
    Average (msecs): #{average_time}
    Max time (msecs): #{longest_time}
    Min time (msecs): #{shortest_time}
    """
  end

  defp average(list) when is_list(list) do
    {sum, count} = Enum.reduce(list, {0, 0}, fn val, {sum, count} ->
      {sum + val, count + 1}
    end)
    sum / count
  end

  defp do_help do
    IO.puts """
    Usage:
    blitzy -n [requests] [url]

    Options:
    -n [--requests] # Number of requests

    Example:
    ./blitzy -n 100 http://google.com
    """
    System.halt(0)
  end
end
