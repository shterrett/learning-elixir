defmodule Times do
  def double(n) do
    n * 2
  end

  def double(n, m) do
    [n * 2, m * 2]
  end

  def triple(n) do
    double(n) + n
  end

  def quadruple(n) do
    double(double(n))
  end

  def factorial(0), do: 1
  def factorial(n)
      when n > 0
      do
        n * factorial(n-1)
      end

  def gcd(x, 0), do: x
  def gcd(x, y), do: gcd(y, rem(x, y))
end

defmodule Sum do
  def sum([]), do: 0
  def sum([n|tail]), do: n + sum(tail)

  def sum_to(n), do: sum(Enum.to_list(1..n))
end

defmodule Search do
  def guess(n, low..high) do
    search(n, bisect(low, high), low..high)
  end

  defp search(m, m, _), do: IO.puts "It's #{m}"
  defp search(m, g, low..high) when low < m and m < high do
    halfway = bisect(low, high)
    IO.puts "Is it #{halfway}?"
    search(m, halfway, halfway..high) || search(m, halfway, low..halfway)
  end
  defp search(m, g, low..high) when low > m or m > high do
  end


  defp bisect(low, high), do: low + div(high - low, 2)
end
