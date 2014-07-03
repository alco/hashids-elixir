ExUnit.start()

defmodule SaltieTest.Helpers do
  def tests_from_fixture(path) do
    File.read!(Path.join([__DIR__, "fixtures", "v0.3.0", path]))
    |> tests_from_string()
  end

  defp tests_from_string(str) do
    str
    |> String.split("\n")
    |> Enum.map(&String.strip/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&match?("#"<>_, &1))
    |> Enum.map(&split_fields/1)
  end

  defp split_fields(str) do
    # [1 2 3 4] <cipher>
    case Regex.run(~r/^\[([\d ]+)\]\s+(.+)$/, str) do
      [_, numstr, cipher] ->
        numbers =
          numstr
          |> String.split(" ")
          |> Enum.map(&String.strip/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.to_integer/1)
        {numbers, String.to_char_list(cipher)}

      _ ->
        # <number> <cipher>
        [numstr, cipher] = String.split(str, " ")
        {String.to_integer(numstr), String.to_char_list(cipher)}
    end
  end
end
