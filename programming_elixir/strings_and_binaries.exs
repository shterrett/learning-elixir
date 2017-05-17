defmodule SaB do
  def printable?(s) do
    Enum.all? s, &(Enum.member? 32..126, &1)
  end

  def anagram?(w1, w2) do
    letter_count(w1) == letter_count(w2)
  end

  defp letter_count(word) do
    Enum.group_by word, &(&1)
  end

  def calculate(s) do
    ops = %{
      ?+ => &+/2,
      ?- => &-/2,
      ?* => &*/2,
      ?/ => &//2
    }
    with { n_1, r_1 } <- parse_number(s),
         { _, r_2 } <- parse_spaces(r_1),
         { op, r_3 } <- parse_operation(r_2),
         { _, r_4 } <- parse_spaces(r_3),
         { n_2, r_5 } <- parse_number(r_4),
         { i_1, _ } <- :string.to_integer(n_1),
         { i_2, _ } <- :string.to_integer(n_2)
    do
      ops[op].(i_1, i_2)
    end
  end

  defp parse_number(s), do: parse_number(s, { [], s })
  defp parse_number([], { number, string }), do: { Enum.reverse(number), string }
  defp parse_number([h|t], {number, string}) do
    if Enum.member? ?0..?9, h do
      parse_number(t, { [h | number], t })
    else
      { Enum.reverse(number), string }
    end
  end

  defp parse_spaces(s), do: parse_spaces(s, { [], s })
  defp parse_spaces([], result), do: result
  defp parse_spaces([h|t], result = { spaces, string }) do
    if ?\  == h do
      parse_spaces(t, { [h | spaces], t })
    else
      result
    end
  end

  defp parse_operation([h|t]), do: { h, t }

  def print_centered(strings) do
    column_width = Enum.max(Enum.map(strings, &String.length/1))
    strings |> Enum.map(&(pad_string(column_width, &1)))
            |> Enum.each(&IO.puts/1)
  end

  def pad_string(width, s) do
    left_delta = div(width - String.length(s), 2)
    right_delta = width - String.length(s) - left_delta
    s |> String.pad_leading(String.length(s) + left_delta)
      |> String.pad_trailing(String.length(s) + left_delta + right_delta)
  end
end
