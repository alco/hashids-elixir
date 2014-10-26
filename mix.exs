defmodule Hashids.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hashids,
      version: "1.0.0",
      elixir: "~> 1.0",
      description: description,
      package: package,
    ]
  end

  defp description do
    "Hashids lets you obfuscate numerical identifiers via reversible mapping."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      contributors: ["Alexei Sholik"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/alco/hashids-elixir",
      }
    ]
  end

  # no deps
  # --alco
end
