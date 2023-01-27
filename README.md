Hashids
=======

[![Build status](https://travis-ci.org/alco/hashids-elixir.svg "Build status")](https://travis-ci.org/alco/hashids-elixir)
[![Module Version](https://img.shields.io/hexpm/v/hashids.svg)](https://hex.pm/packages/hashids)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/hashids/)
[![Total Download](https://img.shields.io/hexpm/dt/hashids.svg)](https://hex.pm/packages/hashids)
[![License](https://img.shields.io/hexpm/l/hashids.svg)](https://github.com/alco/hashids-elixir/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/alco/hashids-elixir.svg)](https://github.com/alco/hashids/commits/master)


Hashids lets you obfuscate numerical identifiers via reversible mapping.

This is a port of [Hashids][1] from JavaScript.

  [1]: http://www.hashids.org/


## Installation

Add Hashids as a dependency to your Mix project:

```elixir
defp deps do
  [
    {:hashids, "~> 2.0"}
  ]
end
```

## Usage

Hashids encodes a list of integers into a string (technically, iodata). Some of the encoding
parameters can be customized.

```elixir
s = Hashids.new([
  salt: "123",  # using a custom salt helps producing unique cipher text
  min_len: 2,   # minimum length of the cipher text (1 by default)
])

cipher1 = Hashids.encode(s, 129)
#=> "pE6"

cipher2 = Hashids.encode(s, [1,2,3,4])
#=> "4bSwImsd"

# decode() always returns a list of numbers

Hashids.decode(s, cipher1)
#=> {:ok, [129]}

Hashids.decode!(s, cipher2)
#=> [1, 2, 3, 4]
```

It is also possible to customize the character set used for the cipher text by
providing a custom alphabet. It has to be at least 16 characters long.

```elixir
defmodule MyAccessToken do
  @cyrillic_alphabet "123456789абвгґдеєжзиіїйклмнопрстуфцчшщьюяАБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФЦЧШЩЬЮЯ"
  @coder Hashids.new(alphabet: @cyrillic_alphabet)

  def encode(token_ids) do
    Hashids.encode(@coder, token_ids)
  end

  def decode(data) do
    Hashids.decode(@coder, data)
  end
end

data = MyAccessToken.encode([1234, 786, 21, 0])
#=> "ЦфюєИНаЛ1И"

MyAccessToken.decode(data)
#=> {:ok, [1234, 786, 21, 0]}
```

## Migrating from 1.0

See the [changelog](./CHANGELOG.md).

## License

This software is licensed under [the MIT license](./LICENSE.md).
