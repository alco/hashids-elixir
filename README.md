Saltie
======

Saltie is a pseudo-encryption library primarily used for obfuscating numerical
identifiers to opaque strings.

This is a port of [Hashids][1], the versioning is kept in sync with it.

  [1]: http://www.hashids.org/


## Installation

Add Saltie as a dependency to your Mix project:

```elixir
defp deps do
  [{:saltie, "== 0.3.0"}]
end
```

## Usage

Saltie encrypts a list of integers into a char list. Some of the encryption
parameters can be customized.

```elixir
s = Saltie.new([
  key: '123',  # using a custom key helps producing unique cipher text
  min_len: 2,  # minimum length of the cipher text (1 by default)
])

cipher1 = Saltie.encrypt(s, 129)
#=> 'pE6'

cipher2 = Saltie.encrypt(s, [1,2,3,4])
#=> '4bSwImsd'

# decrypt() always returns a list of numbers

Saltie.decrypt(s, cipher1)
#=> [129]

Saltie.decrypt(s, cipher2)
#=> [1, 2, 3, 4]
```

It is also possible to customize the character set used for the cipher text by
providing an alphabet as a char list. It has to be at least 16 characters long.

```elixir
s = Saltie.new(alphabet: '1234567890абвгдежизклмн')

cipher = Saltie.encrypt(s, [1234, 786, 21, 0])

List.to_string(cipher)
#=> "имнк40же3ги1з"

Saltie.decrypt(s, cipher)
#=> [1234, 786, 21, 0]
```

## License

This software is licensed under [the MIT license](LICENSE).
