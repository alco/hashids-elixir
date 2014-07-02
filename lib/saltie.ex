defmodule Saltie.Error do
  defexception message: ""
end

defmodule Saltie.Helpers do
  @moduledoc false

  # This is a private module implementing some helpers functions for Saltie

  def consistent_shuffle(alphabet, []), do: alphabet

  def consistent_shuffle(alphabet, key) do
    loop(length(alphabet)-1, 0, 0, alphabet, key, length(key))
  end

  defp loop(0, _, _, alphabet, _, _), do: alphabet

  defp loop(i, v, p, alphabet, key, key_len) do
    key_char = Enum.at(key, v)
    j = rem(2*key_char + v + p, i)

    loop(i-1, rem(v+1, key_len), p+key_char, swap(alphabet, j, i), key, key_len)
  end

  defp swap(list, i, j) do
    {first, [i_elem|rest]} = Enum.split(list, i)
    {second, [j_elem|tail]} = Enum.split(rest, j-i-1)
    List.flatten([first, j_elem, second], [i_elem|tail])
  end


  def encode(num, alphabet) do
    encode(num, alphabet, length(alphabet), [], false)
  end

  defp encode(0, _, _, acc, true), do: acc

  defp encode(num, alphabet, a_len, acc, _) do
    new_acc = [Enum.at(alphabet, rem(num, a_len)) | acc]
    encode(trunc(num / a_len), alphabet, a_len, new_acc, true)
  end


  def decode(str, alphabet) do
    decode(0, str, length(str), alphabet, length(alphabet))
  end

  defp decode(num, [], 0, _, _), do: num

  defp decode(num, [char|rest], s_len, alphabet, a_len) do
    pos = Enum.find_index(alphabet, &(&1 == char))
    rem_len = s_len-1
    new_num = num+pos*:math.pow(a_len, rem_len)
    decode(new_num, rest, rem_len, alphabet, a_len)
  end
end

defmodule Saltie do
  defstruct [
    key: [],
    min_len: 0,
    alphabet: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
    a_len: 62,
    seps: 'cfhistuCFHISTU',
    s_len: 14,
    guards: []
  ]

  @min_alphabet_len 16
  @sep_div 3.5
  @guard_div 12

  def new(opts \\ []) do
    s = struct(%Saltie{}, opts)
    {uniq_alphabet, set} = uniquify_chars(s.alphabet)

    validate_alphabet!(set)
    validate_key!(s.key)
    validate_len!(s.min_len)

    {seps, alphabet} = calculate_seps(s.seps, uniq_alphabet, s.key)

    a_len = length(alphabet)
    alphabet = Saltie.Helpers.consistent_shuffle(alphabet, s.key)
    guard_count = Float.ceil(a_len / @guard_div)
    if a_len < 3 do
      {guards, seps} = Enum.split(seps, guard_count)
    else
      {guards, alphabet} = Enum.split(alphabet, guard_count)
    end
    %Saltie{s |
      alphabet: alphabet,
      a_len: length(alphabet),
      seps: seps,
      s_len: length(seps),
      guards: guards,
    }
  end

  defp validate_alphabet!(set) do
    cond do
      Enum.count(set) < @min_alphabet_len ->
        msg = "Alphabet to short. Need at least #{@min_alphabet_len} characters."
        raise Saltie.Error, message: msg

      Enum.find(set, &(&1 == ?\s)) ->
        msg = "Spaces in alphabet are not allowed."
        raise Saltie.Error, message: msg

      true -> :ok
    end
  end

  defp validate_len!(len) when is_integer(len) and len >= 0, do: :ok
  defp validate_len!(_), do: raise(Saltie.Error, message: "Length has to be a non-negative integer.")

  defp validate_key!(key) when is_list(key), do: :ok
  defp validate_key!(_), do: raise(Saltie.Error, message: "Key has to be a charlist.")

  defp uniquify_chars(charlist) do
    uniquify_chars(charlist, [], HashSet.new)
  end

  defp uniquify_chars([], acc, set), do: {Enum.reverse(acc), set}

  defp uniquify_chars([char|rest], acc, set) do
    if Set.member?(set, char) do
      uniquify_chars(rest, acc, set)
    else
      uniquify_chars(rest, [char|acc], Set.put(set, char))
    end
  end


  defp calculate_seps(seps, alphabet, key) do
    {seps, alphabet} = filter_seps(seps, [], alphabet)
    seps = Saltie.Helpers.consistent_shuffle(seps, key)
    a_len = length(alphabet)
    s_len = length(seps)
    if s_len == 0 or a_len / s_len > @sep_div do
      new_len = max(2, Float.ceil(a_len / @sep_div))
      if new_len > s_len do
        diff = new_len - s_len
        {left, right} = Enum.split(alphabet, diff)
        seps = seps ++ left
        alphabet = right
      else
        seps = Enum.take(seps, new_len)
      end
    end
    {seps, alphabet}
  end

  defp filter_seps([], seps, alphabet) do
    {Enum.reverse(seps), alphabet}
  end

  defp filter_seps([char|rest], seps, alphabet) do
    if j = Enum.find_index(alphabet, &(&1 == char)) do
      # alphabet should not contains seps
      {left, [_|right]} = Enum.split(alphabet, j)
      new_alphabet = left ++ right
      filter_seps(rest, [char|seps], new_alphabet)
      # this.alphabet = this.alphabet.substr(0, j) + " " + this.alphabet.substr(j + 1);
    else
      # seps should contain only characters present in alphabet
      filter_seps(rest, seps, alphabet)
    end
  end


  @spec encrypt(%Saltie{}, non_neg_integer) :: char_list
  def encrypt(s, number) when is_integer(number) and number >= 0 do
    encrypt(s, [number])
  end

  @spec encrypt(%Saltie{}, [non_neg_integer]) :: char_list
  def encrypt(s, numbers) when is_list(numbers) do
    {num_checksum, _} = Enum.reduce(numbers, {0, 100}, fn
      num, _ when num < 0 -> raise Saltie.Erro, message: "Negative numbers not supported"
      num, {cksm, i} -> {cksm + rem(num, i), i+1}
    end)

    a_len = length(s.alphabet)
    lottery = Enum.at(s.alphabet, rem(num_checksum, a_len))
    {precipher, alphabet} = preencode(numbers, 0, [lottery], [lottery|s.key],
                                      s.alphabet, a_len, s.seps, length(s.seps))
    p_len = length(precipher)
    g_len = length(s.guards)

    {interm_cipher, i_len} = extend_precipher1(precipher, p_len, s.min_len, num_checksum, s.guards, g_len)
    {interm_cipher, i_len} = extend_precipher2(interm_cipher, i_len, s.min_len, num_checksum, s.guards, g_len)

    extend_cipher(interm_cipher, i_len, s.min_len, alphabet, a_len)
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
    enc_alphabet = Saltie.Helpers.consistent_shuffle(alphabet, skey)
    last = Saltie.Helpers.encode(num, enc_alphabet)
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
    new_alphabet = Saltie.Helpers.consistent_shuffle(alphabet, alphabet)
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


  @spec decrypt(%Saltie{}, char_list) :: [non_neg_integer]
  def decrypt(s, cipher) do
    guards_str = List.to_string(s.guards)
    cipher_split_at_guards = Regex.split(~r/[#{Regex.escape(guards_str)}]/, List.to_string(cipher))
    cipher_part = case cipher_split_at_guards do
      [_, x]    -> x
      [_, x, _] -> x
      [x|_]     -> x
    end

    if cipher_part && cipher_part != "" do
      {<<lottery::utf8>>, rest_part} = String.split_at(cipher_part, 1)
      rkey = [lottery|s.key]
      seps_str = List.to_string(s.seps)
      Regex.split(~r/[#{Regex.escape(seps_str)}]/, rest_part)
      |> decode_parts(rkey, s.alphabet, s.a_len, [])
    else
      []
    end
  end

  defp decode_parts([], _, _, _, acc), do: Enum.reverse(acc)

  defp decode_parts([part|rest], rkey, alphabet, a_len, acc) do
    buffer = rkey ++ alphabet
    dec_alphabet = Saltie.Helpers.consistent_shuffle(alphabet, Enum.take(buffer, a_len))
    number = Saltie.Helpers.decode(String.to_char_list(part), dec_alphabet)
    decode_parts(rest, rkey, dec_alphabet, a_len, [number|acc])
  end
end

##function Hashids(salt, minHashLength, alphabet) {
##
##  var uniqueAlphabet, i, j, len, sepsLength, diff, guardCount;
##
##  this.version = "0.3.3";
##
##  /* internal settings */
##
##  this.minAlphabetLength = 16;
##  this.sepDiv = 3.5;
##  this.guardDiv = 12;
##
##  /* error messages */
##
##  this.alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
##  this.seps = "cfhistuCFHISTU";
##  this.minHashLength = parseInt(minHashLength, 10) > 0 ? minHashLength : 0;
##  this.salt = (typeof salt === "string") ? salt : "";
##
##  if (typeof alphabet === "string") {
##    this.alphabet = alphabet;
##  }
##
##  for (uniqueAlphabet = "", i = 0, len = this.alphabet.length; i !== len; i++) {
##    if (uniqueAlphabet.indexOf(this.alphabet[i]) === -1) {
##      uniqueAlphabet += this.alphabet[i];
##    }
##  }
##
##  this.alphabet = uniqueAlphabet;
##
##  if (this.alphabet.length < this.minAlphabetLength) {
##    throw this.errorAlphabetLength.replace("X", this.minAlphabetLength);
##  }
##
##  if (this.alphabet.search(" ") !== -1) {
##    throw this.errorAlphabetSpace;
##  }
##
##  /* seps should contain only characters present in alphabet; alphabet should not contains seps */
##
##  for (i = 0, len = this.seps.length; i !== len; i++) {
##
##    j = this.alphabet.indexOf(this.seps[i]);
##    if (j === -1) {
##      this.seps = this.seps.substr(0, i) + " " + this.seps.substr(i + 1);
##    } else {
##      this.alphabet = this.alphabet.substr(0, j) + " " + this.alphabet.substr(j + 1);
##    }
##
##  }
##
##  this.alphabet = this.alphabet.replace(/ /g, "");
##
##  this.seps = this.seps.replace(/ /g, "");
##  this.seps = this.consistentShuffle(this.seps, this.salt);
##
##  if (!this.seps.length || (this.alphabet.length / this.seps.length) > this.sepDiv) {
##
##    sepsLength = Math.ceil(this.alphabet.length / this.sepDiv);
##
##    if (sepsLength === 1) {
##      sepsLength++;
##    }
##
##    if (sepsLength > this.seps.length) {
##
##      diff = sepsLength - this.seps.length;
##      this.seps += this.alphabet.substr(0, diff);
##      this.alphabet = this.alphabet.substr(diff);
##
##    } else {
##      this.seps = this.seps.substr(0, sepsLength);
##    }
##
##  }
##
##  this.alphabet = this.consistentShuffle(this.alphabet, this.salt);
##  guardCount = Math.ceil(this.alphabet.length / this.guardDiv);
##
##  if (this.alphabet.length < 3) {
##    this.guards = this.seps.substr(0, guardCount);
##    this.seps = this.seps.substr(guardCount);
##  } else {
##    this.guards = this.alphabet.substr(0, guardCount);
##    this.alphabet = this.alphabet.substr(guardCount);
##  }
##
##}

##Hashids.prototype.encryptHex = function(str) {
##
##  var i, len, numbers,
##    str = str.toString();
##
##  if (!/^[0-9a-fA-F]+$/.test(str)) {
##    return "";
##  }
##
##  numbers = str.match(/[\w\W]{1,12}/g);
##
##  for (i = 0, len = numbers.length; i !== len; i++) {
##    numbers[i] = parseInt("1" + numbers[i], 16);
##  }
##
##  return this.encrypt.apply(this, numbers);
##
##};

##Hashids.prototype.decryptHex = function(hash) {
##
##  var ret = "",
##    i, len,
##    numbers = this.decrypt(hash);
##
##  for (i = 0, len = numbers.length; i !== len; i++) {
##    ret += (numbers[i]).toString(16).substr(1);
##  }
##
##  return ret;
##
##};
##
