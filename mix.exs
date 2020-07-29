defmodule Kvasir.RocksDB.MixProject do
  use Mix.Project
  @version "0.0.1"

  def project do
    [
      app: :kvasir_rocks_db,
      description: "RocksDB agent cache.",
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # dialyzer: [ignore_warnings: "dialyzer.ignore-warnings", plt_add_deps: true],

      # Docs
      name: "Kvasir RocksDB",
      source_url: "https://github.com/IanLuites/kvasir_rocks_db",
      homepage_url: "https://github.com/IanLuites/kvasir_rocks_db",
      docs: [
        main: "readme",
        extras: ["README.md"],
        source_url: "https://github.com/IanLuites/kvasir_rocks_db"
      ]
    ]
  end

  def package do
    [
      name: :kvasir_rocks_db,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        # Elixir
        "lib/kvasir/rocks_db",
        "lib/kvasir/rocks_db.ex",
        ".formatter.exs",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/kvasir_rocks_db"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Kvasir.RocksDB.Application, []}
    ]
  end

  defp deps do
    [
      {:kvasir_agent, git: "https://github.com/IanLuites/kvasir_agent", branch: "release/v1.0"},
      {:rocksdb,
       git: "https://gitlab.com/michel.boaventura/erlang-rocksdb.git", branch: "fix_otp23"}
    ]
  end
end
