Hashids
=======

[![Build status](https://travis-ci.org/alco/hashids-elixir.svg "Build status")](https://travis-ci.org/alco/hashids-elixir)
[![Hex version](https://img.shields.io/hexpm/v/hashids.svg "Hex version")](https://hex.pm/packages/hashids)
![Hex downloads](https://img.shields.io/hexpm/dt/hashids.svg "Hex downloads")

Hashids lets you obfuscate numerical identifiers via reversible mapping.

This is a port of [Hashids][1] from JavaScript.

  [1]: http://www.hashids.org/


## Installation

Add Hashids as a dependency to your Mix project:

```elixir
defp deps do
  [{:hashids, "~> 2.0"}]
end
```

## Usage

Hashids encodes a list of integers into a char list. Some of the encoding
parameters can be customized.

```elixir
s = Hashids.new([
  salt: "123",  # using a custom salt helps producing unique cipher text
  min_len: 2,   # minimum length of the cipher text (1 by default)
])

#FIXME
cipher1 = Hashids.encode(s, 129)
#=> 'pE6'

#FIXME
cipher2 = Hashids.encode(s, [1,2,3,4])
#=> '4bSwImsd'

# decode() always returns a list of numbers

Hashids.decode(s, cipher1)
#=> {:ok, [129]}

Hashids.decode!(s, cipher2)
#=> [1, 2, 3, 4]
```

It is also possible to customize the character set used for the cipher text by
providing an alphabet as a char list. It has to be at least 16 characters long.

```elixir
s = Hashids.new(alphabet: "1234567890абвгдежизклмн")

cipher = Hashids.encode(s, [1234, 786, 21, 0])

#FIXME
List.to_string(cipher)
#=> "имнк40же3ги1з"

Hashids.decode(s, cipher)
#=> {:ok, [1234, 786, 21, 0]}
```

## License

This software is licensed under [the MIT license](LICENSE).
