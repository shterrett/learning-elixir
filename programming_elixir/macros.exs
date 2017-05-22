defmodule My do
  defmacro inspector(param) do
    IO.inspect(param)
  end

  defmacro qinspector(param) do
    IO.inspect(param)
    param
  end

  defmacro sinspector(param) do
    IO.inspect(param)
    :ok
  end

  defmacro yunquote(code) do
    quote do
      IO.inspect(unquote(code))
    end
  end

  defmacro if(condition, clauses) do
    do_clause = Keyword.get(clauses, :do, nil)
    else_clause = Keyword.get(clauses, :else, nil)
    quote do
      case unquote(condition) do
        false -> unquote(else_clause)
        nil -> unquote(else_clause)
        _ -> unquote(do_clause)
      end
    end
  end

  defmacro unless(condition, clauses) do
    do_clause = Keyword.get(clauses, :do, nil)
    else_clause = Keyword.get(clauses, :else, nil)
    quote do
      case unquote(condition) do
        false -> unquote(do_clause)
        nil -> unquote(do_clause)
        _ -> unquote(else_clause)
      end
    end
  end

  defmacro times_n(n) do
    name = String.to_atom("times_#{n}")
    quote do
      def unquote(name)(x), do: unquote(n) * x
    end
  end
end

defmodule Mult do
  require My

  My.times_n(5)
end
