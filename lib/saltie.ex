defmodule Saltie.Error do
  defexception message: ""
end

defmodule Saltie do
  @moduledoc """
  Saltie is a pseudo-encryption library.
  """

  defstruct [
    key: [],
    min_len: 0,
    alphabet: [], a_len: 0,
    seps: [], s_len: 0,
    guards: [], g_len: 0,
  ]

  #  @type t :: %Saltie{
  #    key: char_list,
  #    min_len: non_neg_integer,
  #    alphabet: char_list, a_len: non_neg_integer,
  #    seps: char_list, s_len: non_neg_integer,
  #    guards: char_list, g_len: non_neg_integer,
  #  }


  @min_alphabet_len 16
  @sep_div 3.5
  @guard_div 12

  @default_alphabet 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
  @seps 'cfhistuCFHISTU'


  alias Saltie.Helpers


  @doc """
  Returns a struct that should be passed to `encrypt/2` and `decrypt/2`.

  Raises `Saltie.Error` if it encounters an invalid option.
  """
  @spec new() :: t
  @spec new(Keywort.t) :: t

  def new(options \\ []) do
    alphabet = Keyword.get(options, :alphabet, @default_alphabet)
    key = Keyword.get(options, :key, [])
    min_len = Keyword.get(options, :min_len, 0)

    {uniq_alphabet, set} = uniquify_chars(alphabet)

    validate_alphabet!(set)
    validate_key!(key)
    validate_len!(min_len)

    a_len = Enum.count(set)
    {seps, alphabet, a_len} = calculate_seps(@seps, uniq_alphabet, a_len, key)

    alphabet = Helpers.consistent_shuffle(alphabet, key)
    guard_count = Float.ceil(a_len / @guard_div)
    if a_len < 3 do
      {guards, seps} = Enum.split(seps, guard_count)
    else
      {guards, alphabet} = Enum.split(alphabet, guard_count)
      a_len = a_len - guard_count
    end
    %Saltie{
      key: key, min_len: min_len,
      alphabet: alphabet, a_len: a_len,
      seps: seps, s_len: length(seps),
      guards: guards, g_len: length(guards),
    }
  end

  defp uniquify_chars(char_list) do
    uniquify_chars(char_list, [], HashSet.new)
  end

  defp uniquify_chars([], acc, set), do: {Enum.reverse(acc), set}

  defp uniquify_chars([char|rest], acc, set) do
    if Set.member?(set, char) do
      uniquify_chars(rest, acc, set)
    else
      uniquify_chars(rest, [char|acc], Set.put(set, char))
    end
  end

  defp validate_alphabet!(set) do
    cond do
      Enum.count(set) < @min_alphabet_len ->
        msg = "Alphabet too short. Need at least #{@min_alphabet_len} characters."
        raise Saltie.Error, message: msg

      Enum.find(set, &(&1 == ?\s)) ->
        msg = "Spaces in the alphabet are not allowed."
        raise Saltie.Error, message: msg

      true -> :ok
    end
  end

  defp validate_key!(key) when is_list(key), do: :ok
  defp validate_key!(_) do
    raise Saltie.Error, message: "Key has to be a (possibly empty) char list."
  end

  defp validate_len!(len) when is_integer(len) and len >= 0, do: :ok
  defp validate_len!(_) do
    raise Saltie.Error, message: "Minimum length has to be a non-negative integer."
  end

  defp calculate_seps(seps, alphabet, a_len, key) do
    {seps, alphabet, a_len} = filter_seps(seps, [], alphabet, a_len)
    seps = Helpers.consistent_shuffle(seps, key)
    s_len = length(seps)
    if s_len == 0 or a_len / s_len > @sep_div do
      new_len = max(2, Float.ceil(a_len / @sep_div))
      if new_len > s_len do
        diff = new_len - s_len
        {left, right} = Enum.split(alphabet, diff)
        seps = seps ++ left
        alphabet = right
        a_len = a_len - diff
      else
        seps = Enum.take(seps, new_len)
      end
    end
    {seps, alphabet, a_len}
  end

  defp filter_seps([], seps, alphabet, a_len) do
    {Enum.reverse(seps), alphabet, a_len}
  end

  defp filter_seps([char|rest], seps, alphabet, a_len) do
    if j = Enum.find_index(alphabet, &(&1 == char)) do
      # alphabet should not contains seps
      {left, [_|right]} = Enum.split(alphabet, j)
      new_alphabet = left ++ right
      filter_seps(rest, [char|seps], new_alphabet, a_len-1)
    else
      # seps should contain only characters present in alphabet
      filter_seps(rest, seps, alphabet, a_len)
    end
  end


  @doc """
  Encrypts the given number or a list of numbers.

  Returns a char list.

  Only non-negative integers are supported.
  """

  @spec encrypt(t, non_neg_integer) :: char_list
  def encrypt(s, number) when is_integer(number) and number >= 0 do
    encrypt(s, [number])
  end

  @spec encrypt(t, [non_neg_integer]) :: char_list
  def encrypt(s, numbers) when is_list(numbers) do
    {num_checksum, _} = Enum.reduce(numbers, {0, 100}, fn
      num, _ when num < 0 or not is_integer(num) ->
        raise Saltie.Error, message: "Expected a non-negative integer"
      num, {cksm, i} ->
        {cksm + rem(num, i), i+1}
    end)

    %Saltie{
      key: key, min_len: min_len,
      alphabet: alphabet, a_len: a_len,
      seps: seps, s_len: s_len,
      guards: guards, g_len: g_len,
    } = s

    lottery = Enum.at(alphabet, rem(num_checksum, a_len))
    {precipher, alphabet} = preencode(numbers, 0, [lottery], [lottery|key],
                                      alphabet, a_len, seps, s_len)
    p_len = length(precipher)

    {interm_cipher, i_len} = extend_precipher1(precipher, p_len, min_len, num_checksum, guards, g_len)
    {interm_cipher, i_len} = extend_precipher2(interm_cipher, i_len, min_len, num_checksum, guards, g_len)

    extend_cipher(interm_cipher, i_len, min_len, alphabet, a_len)
  end


  defp preencode([num], _, inret, rkey, alphabet, a_len, _, _) do
    {outret, new_alphabet, _} = preencode_step(num, inret, rkey, alphabet, a_len)
    {outret, new_alphabet}
  end

  defp preencode([num|rest], i, inret, rkey, alphabet, a_len, seps, seps_len) do
    {outret, new_alphabet, last} = preencode_step(num, inret, rkey, alphabet, a_len)
    ret = seps_step(last, i, num, outret, seps, seps_len)
    preencode(rest, i+1, ret, rkey, new_alphabet, a_len, seps, seps_len)
  end

  defp preencode_step(num, ret, rkey, alphabet, a_len) do
    skey = Stream.concat(rkey, alphabet) |> Enum.take(a_len)
    enc_alphabet = Helpers.consistent_shuffle(alphabet, skey)
    last = Helpers.encode(num, enc_alphabet, a_len)
    {ret ++ last, enc_alphabet, last}
  end

  defp seps_step([char|_], i, num, ret, seps, seps_len) do
    index = rem(num, char+i) |> rem(seps_len)
    ret ++ [Enum.at(seps, index)]
  end


  defp extend_precipher1([char|_]=precipher, p_len, min_len, num_cksm, guards, g_len)
    when p_len < min_len
  do
    index = rem(num_cksm + char, g_len)
    guard = Enum.at(guards, index)
    {[guard|precipher], p_len+1}
  end
  defp extend_precipher1(precipher, p_len, _, _, _, _), do: {precipher, p_len}

  defp extend_precipher2([_,_,char2|_]=precipher, p_len, min_len, num_cksm, guards, g_len)
    when p_len < min_len
  do
    index = rem(num_cksm + char2, g_len)
    guard = Enum.at(guards, index)
    {precipher ++ [guard], p_len+1}
  end
  defp extend_precipher2(precipher, p_len, _, _, _, _), do: {precipher, p_len}


  defp extend_cipher(cipher, c_len, min_len, alphabet, a_len)
    when c_len < min_len
  do
    new_alphabet = Helpers.consistent_shuffle(alphabet, alphabet)
    half_len = trunc(a_len / 2)
    {left, right} = Enum.split(new_alphabet, half_len)

    new_cipher = List.flatten([right, cipher], left)
    new_c_len = c_len + a_len

    excess = new_c_len - min_len
    if excess > 0 do
      new_cipher |> Enum.drop(trunc(excess / 2)) |> Enum.take(min_len)
    else
      extend_cipher(new_cipher, new_c_len, min_len, new_alphabet, a_len)
    end
  end

  defp extend_cipher(cipher, _, _, _, _), do: cipher


  @doc """
  Decrypts the given char list back into a list of numbers.
  """
  @spec decrypt(t, char_list) :: [non_neg_integer]

  def decrypt(s, cipher) do
    %Saltie{
      key: key,
      alphabet: alphabet, a_len: a_len,
      seps: seps, guards: guards,
    } = s

    guards_str = List.to_string(guards)
    cipher_split_at_guards = Regex.split(~r/[#{Regex.escape(guards_str)}]/, List.to_string(cipher))
    cipher_part = case cipher_split_at_guards do
      [_, x]    -> x
      [_, x, _] -> x
      [x|_]     -> x
    end

    if cipher_part && cipher_part != "" do
      {<<lottery::utf8>>, rest_part} = String.split_at(cipher_part, 1)
      rkey = [lottery|key]
      seps_str = List.to_string(seps)
      Regex.split(~r/[#{Regex.escape(seps_str)}]/, rest_part)
      |> decode_parts(rkey, alphabet, a_len, [])
    else
      []
    end
  end

  defp decode_parts([], _, _, _, acc), do: Enum.reverse(acc)

  defp decode_parts([part|rest], rkey, alphabet, a_len, acc) do
    buffer = rkey ++ alphabet
    dec_alphabet = Helpers.consistent_shuffle(alphabet, Enum.take(buffer, a_len))
    number = Helpers.decode(String.to_char_list(part), dec_alphabet, a_len)
    decode_parts(rest, rkey, dec_alphabet, a_len, [number|acc])
  end
end
