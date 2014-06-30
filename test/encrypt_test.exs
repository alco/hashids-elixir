defmodule SaltieTest.Encrypt do
  use ExUnit.Case

  defp tests_from_string(str) do
    str
    |> String.split("\n")
    |> Enum.map(&String.strip/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.split(&1, " "))
    |> Enum.map(fn [numstr, cipherstr] ->
      {String.to_integer(numstr), String.to_char_list(cipherstr)}
    end)
  end

  defp tests_from_fixture(path) do
    File.read!(Path.join([__DIR__, "fixtures", path])) |> tests_from_string()
  end

  test "default key" do
    s = Saltie.new()
    for {num, cipher} <- tests_from_fixture("default_key") do
      assert cipher == Saltie.encrypt(s, num)
    end
  end
end
