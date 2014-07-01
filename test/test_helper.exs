ExUnit.start()

defmodule SaltieTest.Helpers do
  def tests_from_fixture(path) do
    File.read!(Path.join([__DIR__, "fixtures", path])) |> tests_from_string()
  end

  defp tests_from_string(str) do
    str
    |> String.split("\n")
    |> Enum.map(&String.strip/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&match?("#"<>_, &1))
    |> Enum.map(&String.split(&1, " "))
    |> Enum.map(fn [numstr, cipherstr] ->
      {String.to_integer(numstr), String.to_char_list(cipherstr)}
    end)
  end
end
