defmodule Hashids do
  @moduledoc """
  Hashids lets you obfuscate numerical identifiers via reversible mapping.

  ## Example

      h = Hashids.new(salt: "my salt")
      encoded = Hashids.encode(h, [1,2,3])
      {:ok, [1,2,3]} = Hashids.decode(h, encoded)

  """

  defstruct [
    alphabet: [], salt: [], min_len: 0,
    a_len: 0, seps: [], s_len: 0, guards: [], g_len: 0,
  ]

  @typep t :: %Hashids{
    alphabet: char_list, salt: char_list, min_len: non_neg_integer,
    a_len: non_neg_integer, seps: char_list, s_len: non_neg_integer, guards: char_list,
    g_len: non_neg_integer,
  }

  @min_alphabet_len 16
  @sep_div 3.5
  @guard_div 12

  @default_alphabet 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
  @seps 'cfhistuCFHISTU'

  alias Hashids.Helpers

  @doc """
  Create a struct containing the configuration options for Hashids. It should be passed to
  `encode/2` and `decode/2`.

  Raises `Hashids.Error` if it encounters an invalid option.

  ## Options

    * `:alphabet` – a string of characters to be used in the resulting hash value. By default,
      characters from the Latin alphabet and digits are used.
    * `:salt` – a string that will be used to permute the hash value and make it decodable only by
      using the same salt that was provided during encoding. Default: empty string.
    * `:min_len` – the minimum length of the resulting hash. Default: 0.

  """
  @spec new() :: t
  @spec new([{:alphabet, binary} | {:salt, binary} | {:min_len, non_neg_integer}]) :: t

  def new(options \\ []) do
    {uniq_alphabet, a_len} = parse_option!(:alphabet, options)
    salt = parse_option!(:salt, options)
    min_len = parse_option!(:min_len, options)

    {seps, alphabet, a_len} = calculate_seps(@seps, uniq_alphabet, a_len, salt)

    alphabet = Helpers.consistent_shuffle(alphabet, salt)
    guard_count = trunc(Float.ceil(a_len / @guard_div))
    if a_len < 3 do
      {guards, seps} = Enum.split(seps, guard_count)
    else
      {guards, alphabet} = Enum.split(alphabet, guard_count)
      a_len = a_len - guard_count
    end
    %Hashids{
      alphabet: alphabet, salt: salt, min_len: min_len,
      a_len: a_len, seps: seps, s_len: length(seps), guards: guards, g_len: length(guards),
    }
  end

  @doc """
  Encode the given number or a list of numbers.

  Only non-negative integers are supported.
  """
  @spec encode(t, non_neg_integer) :: iodata
  @spec encode(t, [non_neg_integer]) :: iodata

  def encode(s, number) when is_integer(number) and number >= 0 do
    encode(s, [number])
  end

  def encode(s, numbers) when is_list(numbers) do
    {num_checksum, _} = Enum.reduce(numbers, {0, 100}, fn
      num, _ when num < 0 or not is_integer(num) ->
        raise Hashids.Error, message: "Expected a non-negative integer. Got: #{inspect num}"
      num, {cksm, i} ->
        {cksm + rem(num, i), i+1}
    end)

    %Hashids{
      alphabet: alphabet, salt: salt, min_len: min_len,
      a_len: a_len, seps: seps, s_len: s_len, guards: guards, g_len: g_len,
    } = s

    lottery = Enum.at(alphabet, rem(num_checksum, a_len))
    {precipher, p_len, alphabet} =
      preencode(numbers, 0, [lottery], 1, [lottery|salt], alphabet, a_len, seps, s_len)

    {interm_cipher, i_len} =
      extend_precipher1(precipher, p_len, min_len, num_checksum, guards, g_len)
    {interm_cipher, i_len} =
      extend_precipher2(interm_cipher, i_len, min_len, num_checksum, guards, g_len)

    extend_cipher(interm_cipher, i_len, min_len, alphabet, a_len)
    |> List.to_string
  end

  @doc """
  Decode the given iodata back into a list of numbers.
  """
  @spec decode(t, iodata) :: {:ok, [non_neg_integer]} | {:error, :invalid_input_data}

  def decode(
    %Hashids{alphabet: alphabet, salt: salt, a_len: a_len, seps: seps, guards: guards},
    data) when is_list(data) or is_binary(data)
  do
    try do
      cipher_split_at_guards =
        String.split(IO.iodata_to_binary(data), Enum.map(guards, &<<&1::utf8>>))
      cipher_part = case cipher_split_at_guards do
        [_, x]    -> x
        [_, x, _] -> x
        [x|_]     -> x
      end

      result = if cipher_part != "" do
        {<<lottery::utf8>>, rest_part} = String.split_at(cipher_part, 1)
        rkey = [lottery|salt]
        String.split(rest_part, Enum.map(seps, &<<&1::utf8>>))
        |> decode_parts(rkey, alphabet, a_len, [])
      else
        []
      end
      {:ok, result}
    rescue
      _error -> {:error, :invalid_input_data}
    end
  end

  def decode(_, _) do
    raise Hashids.Error, message: "Expected iodata."
  end

  @doc """
  Decode the given iodata back into a list of numbers.

  Will raise a `Hashids.DecodingError` if the provided data is not a valid hash value or a
  Hashids struct with incompatible alphabet.
  """
  @spec decode!(t, iodata) :: [non_neg_integer] | no_return

  def decode!(s, data) do
    case decode(s, data) do
      {:ok, result} -> result
      {:error, _reason} -> raise Hashids.DecodingError, message: "Invalid input data."
    end
  end

  #
  # Privates
  #

  defp uniquify_chars(char_list) do
    uniquify_chars(char_list, [], HashSet.new, 0)
  end

  defp uniquify_chars([], acc, set, nchars), do: {Enum.reverse(acc), set, nchars}

  defp uniquify_chars([char|rest], acc, set, nchars) do
    if Set.member?(set, char) do
      uniquify_chars(rest, acc, set, nchars)
    else
      uniquify_chars(rest, [char|acc], Set.put(set, char), nchars+1)
    end
  end

  defp parse_option!(:alphabet, kw) do
    list = case Keyword.fetch(kw, :alphabet) do
      :error -> @default_alphabet
      # Deprecated. Left for compatibility with 1.0.
      {:ok, list} when is_list(list) -> list
      {:ok, bin} when is_binary(bin) -> String.to_char_list(bin)
      _ ->
        message = "Alphabet has to be a string of at least 16 characters/codepoints."
        raise Hashids.Error, message: message
    end
    {uniq_alphabet, set, nchars} = uniquify_chars(list)
    :ok = validate_alphabet!(set, nchars)
    {uniq_alphabet, nchars}
  end

  defp parse_option!(:salt, kw) do
    case Keyword.fetch(kw, :salt) do
      :error -> []
      # Deprecated. Left for compatibility with 1.0.
      {:ok, list} when is_list(list) -> list
      {:ok, bin} when is_binary(bin) -> String.to_char_list(bin)
      _ -> raise Hashids.Error, message: "Salt has to be a (possibly empty) string."
    end
  end

  defp parse_option!(:min_len, kw) do
    case Keyword.fetch(kw, :min_len) do
      :error -> 0
      {:ok, len} when is_integer(len) and len >= 0 -> len
      _ -> raise Hashids.Error, message: "Min_len has to be a non-negative integer."
    end
  end

  defp validate_alphabet!(set, nchars) do
    cond do
      nchars < @min_alphabet_len ->
        msg = "Alphabet too short. Need at least #{@min_alphabet_len} characters/codepoints."
        raise Hashids.Error, message: msg

      # TODO: use a regex?
      Enum.find(set, &(&1 == ?\s)) ->
        msg = "Spaces in the alphabet are not allowed."
        raise Hashids.Error, message: msg

      true -> :ok
    end
  end

  defp calculate_seps(seps, alphabet, a_len, salt) do
    {seps, alphabet, a_len} = filter_seps(seps, [], alphabet, a_len)
    seps = Helpers.consistent_shuffle(seps, salt)
    s_len = length(seps)
    if s_len == 0 or a_len / s_len > @sep_div do
      new_len = max(2, trunc(Float.ceil(a_len / @sep_div)))
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


  defp preencode([num], _, inret, p_len, rkey, alphabet, a_len, _, _) do
    {outret, step_len, new_alphabet, _} = preencode_step(num, inret, rkey, alphabet, a_len)
    {outret, p_len+step_len, new_alphabet}
  end

  defp preencode([num|rest], i, inret, p_len, rkey, alphabet, a_len, seps, seps_len) do
    {outret, step_len, new_alphabet, last} = preencode_step(num, inret, rkey, alphabet, a_len)
    ret = seps_step(last, i, num, outret, seps, seps_len)
    preencode(rest, i+1, ret, p_len+step_len+1, rkey, new_alphabet, a_len, seps, seps_len)
  end

  defp preencode_step(num, ret, rkey, alphabet, a_len) do
    skey = Stream.concat(rkey, alphabet) |> Enum.take(a_len)
    enc_alphabet = Helpers.consistent_shuffle(alphabet, skey)
    {last, last_len} = Helpers.encode(num, enc_alphabet, a_len)
    {ret ++ last, last_len, enc_alphabet, last}
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
    half_len = div(a_len, 2)
    {left, right} = Enum.split(new_alphabet, half_len)

    new_cipher = List.flatten([right, cipher], left)
    new_c_len = c_len + a_len

    excess = new_c_len - min_len
    if excess > 0 do
      new_cipher |> Enum.drop(div(excess, 2)) |> Enum.take(min_len)
    else
      extend_cipher(new_cipher, new_c_len, min_len, new_alphabet, a_len)
    end
  end

  defp extend_cipher(cipher, _, _, _, _), do: cipher


  defp decode_parts([], _, _, _, acc), do: Enum.reverse(acc)

  defp decode_parts([part|rest], rkey, alphabet, a_len, acc) do
    buffer = rkey ++ alphabet
    dec_alphabet = Helpers.consistent_shuffle(alphabet, Enum.take(buffer, a_len))
    number = Helpers.decode(String.to_char_list(part), dec_alphabet, a_len)
    decode_parts(rest, rkey, dec_alphabet, a_len, [number|acc])
  end
end
