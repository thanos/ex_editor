defmodule ExEditor.MixProject do
  use Mix.Project

  @version "0.3.0"
  @source_url "https://github.com/thanos/ex_editor"

  def project do
    [
      app: :ex_editor,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "ExEditor",
      source_url: @source_url,
      test_coverage: [tool: ExCoveralls],
      aliases: [
        verify: &verify/1
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix_live_view, ">= 0.19.0", optional: true},
      {:phoenix_html, ">= 3.0.0", optional: true},
      {:phoenix_test, "~> 0.2", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  defp description do
    "A headless code editor library for Phoenix LiveView applications with a plugin system for extensibility."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Thanos Vassilakis"],
      files:
        ~w(lib/ex_editor lib/ex_editor_web lib/ex_editor.ex lib/ex_editor_web.ex priv) ++
          ~w(CHANGELOG.md LICENSE README.md mix.exs)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides/plugins.md",
        "guides/integration.md"
      ],
      groups_for_modules: [
        "Editor Core": [ExEditor, ExEditor.Editor, ExEditor.Document, ExEditor.History],
        Plugins: [ExEditor.Plugin],
        Highlighters: [ExEditor.Highlighter, ExEditor.Highlighters],
        "Web Components": [ExEditorWeb, ExEditorWeb.LiveEditor],
        Utilities: [ExEditor.LineNumbers, ExEditor.HighlightedLines]
      ]
    ]
  end

  defp verify(_) do
    steps = [
      {"compile --warnings-as-errors", :dev},
      {"format --check-formatted", :dev},
      {"credo --strict", :dev},
      {"sobelow --config", :dev},
      # {"dialyzer", :dev},
      {"test --cover", :test},
      {"docs --warnings-as-errors", :dev}
    ]

    Enum.each(steps, fn {task, env} ->
      Mix.shell().info([:bright, "==> mix #{task}", :reset])

      {_, exit_code} =
        System.cmd("mix", String.split(task),
          env: [{"MIX_ENV", to_string(env)}],
          into: IO.stream()
        )

      if exit_code != 0 do
        Mix.raise("mix #{task} failed (exit code #{exit_code})")
      end
    end)

    Mix.shell().info([:green, :bright, "\nAll verification checks passed!", :reset])
  end
end
