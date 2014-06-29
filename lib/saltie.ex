defmodule Saltie.Helpers do
  ##Hashids.prototype.consistentShuffle = function(alphabet, salt) {
  ##
  ##  var integer, j, temp, i, v, p;
  ##
  ##  if (!salt.length) {
  ##    return alphabet;
  ##  }
  ##
  ##  for (i = alphabet.length - 1, v = 0, p = 0; i > 0; i--, v++) {
  ##
  ##    v %= salt.length;
  ##    p += integer = salt[v].charCodeAt(0);
  ##    j = (integer + v + p) % i;
  ##
  ##    temp = alphabet[j];
  ##    alphabet = alphabet.substr(0, j) + alphabet[i] + alphabet.substr(j + 1);
  ##    alphabet = alphabet.substr(0, i) + temp + alphabet.substr(i + 1);
  ##
  ##  }
  ##
  ##  return alphabet;
  ##
  ##};
  def consistent_shuffle(alphabet, nil), do: alphabet

  def consistent_shuffle(alphabet, salt) do
    loop(length(alphabet)-1, 0, 0, alphabet, salt, length(salt))
  end

  defp loop(0, _, _, alphabet, _, _), do: alphabet

  defp loop(i, v, p, alphabet, salt, salt_len) do
    salt_char = Enum.at(salt, v)
    j = rem(2*salt_char + v + p, i)

    loop(i-1, rem(v+1, salt_len), p+salt_char, swap(alphabet, j, i), salt, salt_len)
  end

  defp swap(list, i, j) do
    {first, [i_elem|rest]} = Enum.split(list, i)
    {second, [j_elem|tail]} = Enum.split(rest, j-i-1)
    List.flatten([first, j_elem, second], [i_elem|tail])
  end

  ##hash = function(input, alphabet) {
  ##
  ##  var hash = "",
  ##    alphabetLength = alphabet.length;
  ##
  ##  do {
  ##    hash = alphabet[input % alphabetLength] + hash;
  ##    input = parseInt(input / alphabetLength, 10);
  ##  } while (input);
  ##
  ##  return hash;
  ##
  ##};
  def encode(num, alphabet) do
    encode(num, alphabet, length(alphabet), [])
  end

  defp encode(0, _, _, acc), do: acc

  defp encode(num, alphabet, a_len, acc) do
    new_acc = [Enum.at(alphabet, rem(num, a_len)) | acc]
    encode(trunc(num / a_len), alphabet, a_len, new_acc)
  end

  ##Hashids.prototype.unhash = function(input, alphabet) {
  ##
  ##  var number = 0, pos, i;
  ##
  ##  for (i = 0; i < input.length; i++) {
  ##    pos = alphabet.indexOf(input[i]);
  ##    number += pos * Math.pow(alphabet.length, input.length - i - 1);
  ##  }
  ##
  ##  return number;
  ##
  ##};
  def decode(str, alphabet) do
    decode(0, str, length(str), alphabet, length(alphabet))
  end

  defp decode(num, [], 0, _, _), do: num

  defp decode(num, [char|rest], s_len, alphabet, a_len) do
    pos = Enum.find_index(alphabet, &(&1 == char))
    rem_len = s_len-1
    new_num = num+pos*trunc(:math.pow(a_len, rem_len))
    decode(new_num, rest, rem_len, alphabet, a_len)
  end
end

defmodule Saltie do
  defstruct salt: "", min_len: 0, alphabet: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'

  @min_alphabet_len 16

  def new(opts) do
    s = struct(%Saltie{}, opts)
    {uniq_alphabet, set} = uniquify_chars(s.alphabet)
    %Saltie{s |
      alphabet: validate_alphabet!(set) && uniq_alphabet,
      min_len:  validate_len!(s.min_len),
      salt:     validate_salt!(s.salt)
    }
  end

  defp validate_alphabet!(set) do
    cond do
      Enum.count(set) < @min_alphabet_len ->
        raise "Alphabet to short. Need at least #{@min_alphabet_len} characters."

      Enum.find(set, ?\s) ->
        raise "Spaces in alphabet are not allowed."
    end
  end

  defp validate_len!(len) when is_integer(len) and len >= 0, do: :ok
  defp validate_len!(_), do: raise "Length has to be a non-negative integer."

  defp validate_salt!(salt) when is_binary(salt), do: :ok
  defp validate_salt!(_), do: raise "Salt has to be a binary."

  defp uniquify_chars(charlist) do
    set = Enum.into(charlist, HashSet.new)
    {Enum.to_list(set), set}
  end


  @spec encrypt(%Saltie{}, integer) :: String.t
  def encrypt(s, number) when is_integer(number) do
    encrypt(s, [number])
  end

  @spec encrypt(%Saltie{}, [integer]) :: String.t
  def encrypt(s, numbers) when is_list(numbers) do
  end
##Hashids.prototype.encode = function(numbers) {
##
##  var ret, lottery, i, len, number, buffer, last, sepsIndex, guardIndex, guard, halfLength, excess,
##    alphabet = this.alphabet,
##    numbersSize = numbers.length,
##    numbersHashInt = 0;
##
##  for (i = 0, len = numbers.length; i !== len; i++) {
##    numbersHashInt += (numbers[i] % (i + 100));
##  }
##
##  lottery = ret = alphabet[numbersHashInt % alphabet.length];
##  for (i = 0, len = numbers.length; i !== len; i++) {
##
##    number = numbers[i];
##    buffer = lottery + this.salt + alphabet;
##
##    alphabet = this.consistentShuffle(alphabet, buffer.substr(0, alphabet.length));
##    last = this.hash(number, alphabet);
##
##    ret += last;
##
##    if (i + 1 < numbersSize) {
##      number %= (last.charCodeAt(0) + i);
##      sepsIndex = number % this.seps.length;
##      ret += this.seps[sepsIndex];
##    }
##
##  }
##
##  if (ret.length < this.minHashLength) {
##
##    guardIndex = (numbersHashInt + ret[0].charCodeAt(0)) % this.guards.length;
##    guard = this.guards[guardIndex];
##
##    ret = guard + ret;
##
##    if (ret.length < this.minHashLength) {
##
##      guardIndex = (numbersHashInt + ret[2].charCodeAt(0)) % this.guards.length;
##      guard = this.guards[guardIndex];
##
##      ret += guard;
##
##    }
##
##  }
##
##  halfLength = parseInt(alphabet.length / 2, 10);
##  while (ret.length < this.minHashLength) {
##
##    alphabet = this.consistentShuffle(alphabet, alphabet);
##    ret = alphabet.substr(halfLength) + ret + alphabet.substr(0, halfLength);
##
##    excess = ret.length - this.minHashLength;
##    if (excess > 0) {
##      ret = ret.substr(excess / 2, this.minHashLength);
##    }
##
##  }
##
##  return ret;
##
##};

  @spec decrypt(%Saltie{}, String.t) :: [integer]
  def decrypt(s, string) do
  end
##
##Hashids.prototype.decode = function(hash, alphabet) {
##
##  var ret = [],
##    i = 0,
##    lottery, len, subHash, buffer,
##    r = new RegExp("[" + this.guards + "]", "g"),
##    hashBreakdown = hash.replace(r, " "),
##    hashArray = hashBreakdown.split(" ");
##
##  if (hashArray.length === 3 || hashArray.length === 2) {
##    i = 1;
##  }
##
##  hashBreakdown = hashArray[i];
##  if (typeof hashBreakdown[0] !== "undefined") {
##
##    lottery = hashBreakdown[0];
##    hashBreakdown = hashBreakdown.substr(1);
##
##    r = new RegExp("[" + this.seps + "]", "g");
##    hashBreakdown = hashBreakdown.replace(r, " ");
##    hashArray = hashBreakdown.split(" ");
##
##    for (i = 0, len = hashArray.length; i !== len; i++) {
##
##      subHash = hashArray[i];
##      buffer = lottery + this.salt + alphabet;
##
##      alphabet = this.consistentShuffle(alphabet, buffer.substr(0, alphabet.length));
##      ret.push(this.unhash(subHash, alphabet));
##
##    }
##
##    if (this.encode(ret) !== hash) {
##      ret = [];
##    }
##
##  }
##
##  return ret;
##
##};
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

##Hashids.prototype.encrypt = function() {
##
##  var ret = "",
##    i, len,
##    numbers = Array.prototype.slice.call(arguments);
##
##  if (!numbers.length) {
##    return ret;
##  }
##
##  if (numbers[0] instanceof Array) {
##    numbers = numbers[0];
##  }
##
##  for (i = 0, len = numbers.length; i !== len; i++) {
##    if (typeof numbers[i] !== "number" || numbers[i] % 1 !== 0 || numbers[i] < 0) {
##      return ret;
##    }
##  }
##
##  return this.encode(numbers);
##
##};

##Hashids.prototype.decrypt = function(hash) {
##
##  var ret = [];
##
##  if (!hash.length || typeof hash !== "string") {
##    return ret;
##  }
##
##  return this.decode(hash, this.alphabet);
##
##};

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
