list_concat = fn [a, b], [c, d] -> [a, b, c, d] end
sum = fn (a, b, c) -> a + b + c end
pair_tuple_to_list = fn { a, b } -> [a, b] end

fizz_buzz = fn
  0, 0, _ -> "FizzBuzz"
  0, _, _ -> "Fizz"
  _, 0, _ -> "Buzz"
  _, _, a -> a
end

fizzy = fn n -> fizz_buzz.(rem(n, 3), rem(n, 5), n) end

prefix = fn s1 ->
  fn s2 ->
    "#{s1} #{s2}"
  end
end

IO.puts "Rewritten functions"
IO.inspect(Enum.map [1, 2, 3, 4], &(&1 + 2))
Enum.map [1, 2, 3, 4], &IO.inspect/1
