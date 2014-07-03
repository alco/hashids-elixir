defmodule Saltie.Mixfile do
  use Mix.Project

  def project do
    [
      app: :saltie,
      version: "0.4.0-dev",
      elixir: "~> 0.13.3 or ~> 0.14.0",
      description: description,
      package: package,
    ]
  end

  defp description do
    "Saltie is a pseudo-encryption library primarily used for obfuscating " <>
    "numerical identifiers to opaque strings."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      contributors: ["Alexei Sholik"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/alco/saltie",
      }
    ]
  end

  # no deps
  # --alco
end
