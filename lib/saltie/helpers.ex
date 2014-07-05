defmodule Saltie.Helpers do
  @moduledoc false

  # This is a private module implementing some helper functions for Saltie

  # Shuffles elements in the list according to the key. Doesn't change the
  # length of the list.
  def consistent_shuffle(list, []), do: list

  def consistent_shuffle(list, key) do
    loop(length(list)-1, 0, 0, list, key, length(key))
  end

  defp loop(0, _, _, list, _, _), do: list

  defp loop(i, v, p, list, key, key_len) do
    key_char = Enum.at(key, v)
    j = rem(2*key_char + v + p, i)

    loop(i-1, rem(v+1, key_len), p+key_char, swap(list, j, i), key, key_len)
  end

  defp swap(list, i, j) do
    {first, [i_elem|rest]} = Enum.split(list, i)
    {second, [j_elem|tail]} = Enum.split(rest, j-i-1)
    List.flatten([first, j_elem, second], [i_elem|tail])
  end


  # Builds up a string encoding of the numbers using characters from the
  # alphabet
  def encode(num, alphabet, a_len) do
    encode(num, alphabet, a_len, [], false)
  end

  defp encode(0, _, _, acc, true), do: acc

  defp encode(num, alphabet, a_len, acc, _) do
    new_acc = [Enum.at(alphabet, rem(num, a_len)) | acc]
    encode(div(num, a_len), alphabet, a_len, new_acc, true)
  end


  # Decodes the string back into a number
  def decode(str, alphabet, a_len) do
    decode(0, str, length(str), alphabet, a_len)
  end

  defp decode(num, [], 0, _, _), do: num

  defp decode(num, [char|rest], s_len, alphabet, a_len) do
    pos = Enum.find_index(alphabet, &(&1 == char))
    rem_len = s_len-1
    new_num = num+pos*ipow(a_len, rem_len)
    decode(new_num, rest, rem_len, alphabet, a_len)
  end

  use Bitwise

  defp ipow(_, 0), do: 1
  defp ipow(a, 1), do: a

  defp ipow(a, n) when band(n, 1) === 0 do
    tmp = ipow(a, n >>> 1)
    tmp * tmp
  end

  defp ipow(a, n) do
    a * ipow(a, n-1)
  end
end
