defmodule Hashids.Mixfile do
  use Mix.Project

  @version "2.0.3"

  def project do
    [
      app: :hashids,
      version: @version,
      elixir: "~> 1.4",
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/alco/hashids-elixir",
      docs: [
        main: Hashids,
        source_ref: "v#{@version}",
      ],
    ]
  end

  defp description do
    "Hashids lets you obfuscate numerical identifiers via reversible mapping."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
      maintainers: ["Alexei Sholik"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/alco/hashids-elixir",
      }
    ]
  end

  defp deps do
    [
      {:benchfella, "~> 0.2", only: :bench},
      {:ex_doc, "> 0.0.0", only: :dev},
    ]
  end
end
