defmodule Mynum do
  def map(f, l) do
    { :done, result } = Enumerable.reduce(l, { :cont, [] }, fn (entry, list) ->
                          { :cont, [f.(entry) | list] }
                        end)
    Enum.reverse result
  end

  def each(f, l) do
    Enumerable.reduce(l, { :cont, :ok }, fn (entry, status) ->
      f.(entry)
      { :cont, :ok }
    end)
    :ok
  end

  def filter(f, l) do
    { :done, result } = Enumerable.reduce(l, { :cont, [] }, fn (entry, list) ->
      if f.(entry) do
        { :cont, [entry | list] }
      else
        { :cont, list }
      end
    end)

    Enum.reverse result
  end
end
