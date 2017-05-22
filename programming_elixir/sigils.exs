defmodule Sigils do
  def sigil_v(lines, opts) do
    lines
    |> String.split("\n")
    |> Enum.map(&String.rstrip/1)
    |> Enum.reject(&("" === &1))
    |> Enum.map(&(String.split(&1, ",")))
    |> Enum.map(fn row ->
                  Enum.map(row, fn item -> convert_numbers(item) end)
                end)
    |> fold_headers(opts)
  end

  defp convert_numbers(word) do
    case Float.parse(word) do
      { n, "" } -> n
      _ -> word
    end
  end

  defp fold_headers(data, ''), do: data
  defp fold_headers([headers | data], 'h') do
    keys = Enum.map headers, &String.to_atom/1
    Enum.map data, &(Enum.zip(keys, &1))
  end
end
