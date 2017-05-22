defprotocol Caesar do
  def encrypt(str, shift)
  def rot13(str)
end

defimpl Caesar, for: BitString do
  def rot13(str), do: encrypt(str, 13)

  def encrypt(str, shift) do
    Caesar.encrypt(String.to_char_list(str), shift)
  end
end

defimpl Caesar, for: List do
  @uppercase_start 65
  @uppercase_end 90
  @lowercase_start 97
  @lowercase_end 123

  def rot13(str), do: encrypt(str, 13)

  def encrypt([], _), do: ''
  def encrypt([h|t], n) when h in @lowercase_start..@lowercase_end do
    [wraparound(h + n, @lowercase_start, @lowercase_end) | encrypt(t, n)]
  end
  def encrypt([h|t], n) when n in @uppercase_start..@uppercase_end do
    [wraparound(h + n, @uppercase_start, @uppercase_end) | encrypt(t, n)]
  end

  defp wraparound(n, s, e) when n > e, do: s + (n - e)
  defp wraparound(n, _, e) when n <= e, do: n
end
