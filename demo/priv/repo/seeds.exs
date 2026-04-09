# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Demo.Repo
alias Demo.CMS.CodeSnippet

# Only seed if no snippets exist
if Repo.aggregate(CodeSnippet, :count) == 0 do
  Repo.insert!(%CodeSnippet{
    name: "GenServer Example",
    code: """
    defmodule MyApp.Counter do
      use GenServer

      # Client API

      def start_link(initial_value \\\\ 0) do
        GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
      end

      def increment, do: GenServer.call(__MODULE__, :increment)
      def decrement, do: GenServer.call(__MODULE__, :decrement)
      def value, do: GenServer.call(__MODULE__, :value)

      # Server Callbacks

      @impl true
      def init(initial_value) do
        {:ok, initial_value}
      end

      @impl true
      def handle_call(:increment, _from, state) do
        {:reply, state + 1, state + 1}
      end

      def handle_call(:decrement, _from, state) do
        {:reply, state - 1, state - 1}
      end

      def handle_call(:value, _from, state) do
        {:reply, state, state}
      end
    end
    """
  })

  Repo.insert!(%CodeSnippet{
    name: "Phoenix LiveView Component",
    code: """
    defmodule MyAppWeb.SearchLive do
      use MyAppWeb, :live_view

      @impl true
      def mount(_params, _session, socket) do
        {:ok,
         socket
         |> assign(:query, "")
         |> assign(:results, [])}
      end

      @impl true
      def handle_event("search", %{"query" => query}, socket) do
        results = MyApp.Search.find(query)
        {:noreply, assign(socket, query: query, results: results)}
      end

      @impl true
      def render(assigns) do
        ~H\"\"\"
        <div class="mx-auto max-w-lg">
          <form phx-change="search" phx-submit="search">
            <input
              type="text"
              name="query"
              value={@query}
              placeholder="Search..."
              phx-debounce="300"
            />
          </form>

          <ul :for={result <- @results}>
            <li>{result.name}</li>
          </ul>
        </div>
        \"\"\"
      end
    end
    """
  })

  Repo.insert!(%CodeSnippet{
    name: "Ecto Schema with Changeset",
    code: """
    defmodule MyApp.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :name, :string
        field :email, :string
        field :age, :integer
        has_many :posts, MyApp.Blog.Post

        timestamps()
      end

      @required_fields ~w(name email)a
      @optional_fields ~w(age)a

      def changeset(user, attrs) do
        user
        |> cast(attrs, @required_fields ++ @optional_fields)
        |> validate_required(@required_fields)
        |> validate_format(:email, ~r/@/)
        |> validate_number(:age, greater_than: 0, less_than: 150)
        |> unique_constraint(:email)
      end
    end
    """
  })
end
