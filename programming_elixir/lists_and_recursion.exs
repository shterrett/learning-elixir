defmodule LR do
  @uppercase_start 65
  @uppercase_end 90
  @lowercase_start 97
  @lowercase_end 123

  def sum_without_accumulator([a]), do: a

  def sum_without_accumulator([h|t]) do
    h + sum_without_accumulator(t)
  end

  def mapsum([a], f), do: f.(a)
  def mapsum([h|t], f) do
    f.(h) + mapsum(t, f)
  end

  def maxlist([h|t]), do: maxlist(h, t)
  def maxlist(m, [a]), do: max(m, a)
  def maxlist(m, [h|t]) do
    maxlist(max(m, h), t)
  end

  def caesar([], n), do: ''
  def caesar([h|t], n) when h in @lowercase_start..@lowercase_end do
    [wraparound(h + n, @lowercase_start, @lowercase_end) | caesar(t, n)]
  end
  def caesar([h|t], n) when n in @uppercase_start..@uppercase_end do
    [wraparound(h + n, @uppercase_start, @uppercase_end) | caesar(t, n)]
  end

  defp wraparound(n, s, e) when n > e, do: s + (n - e)
  defp wraparound(n, _, e) when n <= e, do: n

  def span(from, to) when from == to, do: [from]
  def span(from, to) when from < to do
    [from | span(from + 1, to)]
  end

  def all?([], f), do: false
  def all?([a], f), do: f.(a)
  def all?([h|t], f) do
    f.(h) && all?(t, f)
  end

  def each([], _) do
  end
  def each([h|t], f) do
    f.(h)
    each(t, f)
  end

  def filter([], _), do: []
  def filter([h|t], f) do
    if f.(h) do
      [h | filter(t, f)]
    else
      filter(t, f)
    end
  end

  def split(l, c), do: do_split([], l, c)
  defp do_split(f, l, 0), do: [Enum.reverse(f), l]
  defp do_split(f, [], _), do: [Enum.reverse(f), []]
  defp do_split(f, [h|t], c) do
    do_split([h | f], t, c - 1)
  end

  def take(_, 0), do: []
  def take([], _), do: []
  def take([h|t], c) do
    [h | take(t, c - 1)]
  end

  def flatten([]), do: []
  def flatten([h|t])
    when is_list(h) do
      flatten(h) ++ flatten(t)
  end
  def flatten([h|t])
    when not is_list(h) do
      [h | flatten(t) ]
  end

  def primes(n) do
    Enum.reduce(span(3, n), [2], &sieve/2)
  end

  defp sieve(next, primes) do
    if not Enum.any? primes, &(rem(next, &1) == 0) do
      [next | primes]
    else
      primes
    end
  end

  def add_tax(rates, orders) do
    Enum.map(orders,
             fn order = %{ ship_to: ship_to, net_amount: net_amount } ->
               Map.put_new(order, :total_amount, net_amount + Map.get(rates, ship_to, 0))
             end
    )
  end
end
