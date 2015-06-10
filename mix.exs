defmodule Hashids.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hashids,
      version: "2.0.0-dev",
      elixir: "~> 1.0",
      deps: deps,
      description: description,
      package: package,
      source_url: "https://github.com/alco/hashids-elixir",
      docs: [
        main: Hashids,
      ],
    ]
  end

  defp description do
    "Hashids lets you obfuscate numerical identifiers via reversible mapping."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
      contributors: ["Alexei Sholik"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/alco/hashids-elixir",
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.7", only: :docs},
      {:benchfella, "~> 0.2", only: :bench},
    ]
  end
end
