Changelog
=========

## v2.1.0 - Jan 27, 2023

  * Fixed compilation warning.

  * Bumped ex_doc version.

  * Bumped the minimum support Elixir version.

## v2.0.0 - Jun 10, 2015

  * `Hashids.new()` takes strings for the `:alphabet` and `:salt` options (instead of char lists).

  * `Hashids.encode()` returns iodata instead of a char list.

  * `Hashids.decode()` takes iodata instead of a char list and returns `{:ok, result}` or
    `{:error, :invalid_input_data}`.

  * `Hashids.decode!()` has been added. It returns the bare result or raises.

## v1.0.0 – Oct 26, 2014

  * Initial release on hex.pm.
