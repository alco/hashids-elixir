defmodule Hashids.Mixfile do
  use Mix.Project

  @source_url "https://github.com/alco/hashids-elixir"
  @version "2.1.0"

  def project do
    [
      app: :hashids,
      version: @version,
      elixir: "~> 1.11",
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  defp package do
    [
      description: "Hashids lets you obfuscate numerical identifiers via reversible mapping.",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "CHANGELOG.md"],
      maintainers: ["Oleksii Sholik"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/hashids/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp deps do
    [
      {:benchfella, "~> 0.2", only: :bench},
      {:ex_doc, "> 0.0.0", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", {:"LICENSE.md", [title: "License"]}, "README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
