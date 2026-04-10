defmodule DemoWeb.Admin.Fields.JsonField do
  @config_schema [
    placeholder: [
      doc: "Placeholder value or function that receives the assigns.",
      type: {:or, [:string, {:fun, 1}]}
    ],
    debounce: [
      doc: "Timeout value (in milliseconds), \"blur\" or function that receives the assigns.",
      type: {:or, [:pos_integer, :string, {:fun, 1}]}
    ],
    throttle: [
      doc: "Timeout value (in milliseconds) or function that receives the assigns.",
      type: {:or, [:pos_integer, {:fun, 1}]}
    ],
    rows: [
      doc: "Number of visible text lines for the control.",
      type: :non_neg_integer,
      default: 2
    ],
    readonly: [
      doc: "Sets the field to readonly. Also see the [panels](/guides/fields/readonly.md) guide.",
      type: {:or, [:boolean, {:fun, 1}]}
    ]
  ]

  @moduledoc """
  A field for handling long text values.

  ## Field-specific options

  See `Backpex.Field` for general field options.

  #{NimbleOptions.docs(@config_schema)}
  """
  use Backpex.Field, config_schema: @config_schema

  @impl Backpex.Field
  def render_value(assigns) do
    # Get the field value from the item
    field_value = Map.get(assigns.item, assigns.name) |> make_string()

    # For index/resource views, show truncated text
    if assigns.live_action in [:index, :resource_action] do
      assigns = assign(assigns, :highlight_field_value, highlight_text(field_value))

      ~H"""
      <p class="truncate" phx-no-format>{raw @highlight_field_value }</p>
      """
    else
      # For show view, display with line numbers similar to editor
      render_args_with_lines(field_value)
    end
  end

  defp render_args_with_lines(content) do
    assigns = %{content: content}

    ~H"""
    <div class="border border-gray-300 rounded-lg overflow-hidden bg-slate-900">
      <div class="ex-editor-wrapper" style="display: flex;">
        <div
          class="ex-editor-gutter"
          style="padding-top: 8px; padding-right: 12px; padding-left: 8px; background-color: #1e293b; color: #64748b; font-family: 'Monaco', 'Menlo', monospace; font-size: 14px; line-height: 1.5; user-select: none; border-right: 1px solid #334155;"
        >
          <%= for num <- 1..line_count(@content) do %>
            <div class="ex-editor-line-number" style="text-align: right;">{num}</div>
          <% end %>
        </div>
        <div class="ex-editor-code-area" style="flex: 1; overflow-x: auto;">
          <pre
            class="ex-editor-highlight"
            style="padding: 8px; margin: 0; background-color: #0f172a; color: #e2e8f0; font-family: 'Monaco', 'Menlo', monospace; font-size: 14px; line-height: 1.5; overflow: hidden;"
          ><%= raw highlight_text(@content) %></pre>
        </div>
      </div>
    </div>
    """
  end

  @impl Backpex.Field
  def render_form(assigns) do
    # Get the field value from the form field
    field_value = assigns.form[assigns.name]

    # Extract content, handling form field values and database values
    # The form field value can be: string (from form submission), map (from database), or empty
    content =
      case field_value && field_value.value do
        val when is_binary(val) and val != "" ->
          # Non-empty string value from form submission
          val

        val when is_map(val) and map_size(val) > 0 ->
          # Non-empty map from database/form
          make_string(val)

        _other ->
          # Empty or nil value - check database for original value
          case assigns.item && Map.get(assigns.item, assigns.name) do
            val when is_map(val) and map_size(val) > 0 -> make_string(val)
            val when is_binary(val) and val != "" -> val
            _ -> ""
          end
      end

    # Format errors for display
    error_messages =
      field_value.errors
      |> Enum.map(&format_error/1)
      |> Enum.map(&"• #{&1}")

    assigns =
      assigns
      |> assign(:content, content)
      |> assign(:error_messages, error_messages)
    ~H"""
    <div>
      <Layout.field_container>
        <:label align={Backpex.Field.align_label(@field_options, assigns, :top)}>
          <Layout.input_label for={@form[@name]} text={@field_options[:label]} />
        </:label>

    <!-- Use ExEditor LiveEditor component for syntax-highlighted editing -->
        <div class="border border-gray-300 rounded-lg overflow-hidden mb-2 h-96">
          <.live_component
            module={ExEditorWeb.LiveEditor}
            id={"editor_#{@name}"}
            content={@content}
            language={:elixir}
            on_change="args_changed"
            debounce={100}
            readonly={@readonly}
          />
        </div>

    <!-- Hidden input field to sync with form -->
        <input
          type="hidden"
          name={@form[@name].name}
          value={@content}
          id={"#{@form[@name].id}_editor_sync"}
          phx-hook="EditorFormSync"
          data-field-id={@form[@name].id}
        />

    <!-- Help text -->
        <%= if help_text = Backpex.Field.help_text(@field_options, assigns) do %>
          <p class="text-sm text-gray-500 mt-1">{help_text}</p>
        <% end %>

    <!-- Field errors -->
        <%= if Enum.any?(@error_messages) do %>
          <div class="text-sm text-red-600 mt-1">
            {raw Enum.join(@error_messages, "<br>")}
          </div>
        <% end %>
      </Layout.field_container>
    </div>
    """
  end

  defp line_count(nil), do: 1

  defp line_count(content) when is_binary(content) do
    content
    |> String.split("\n")
    |> length()
  end

  defp line_count(content) do
    # Handle non-binary values (like maps) - convert to string first
    content
    |> make_string()
    |> String.split("\n")
    |> length()
  end

  defp highlight_text(nil), do: ""

  defp highlight_text(content) do
    editor = ExEditor.Editor.new(content: make_string(content))
    editor = ExEditor.Editor.set_highlighter(editor, ExEditor.Highlighters.JSON)
    ExEditor.Editor.get_highlighted_content(editor)
  end

  def make_string(nil), do: ""
  def make_string(content) when is_binary(content), do: content

  def make_string(content) when is_map(content) do
    case Phoenix.json_library().encode(content) do
      {:ok, json} -> json
      {:error, _} -> ""
    end
  end

  def make_string(_content), do: ""

  defp format_error({msg, _opts}) when is_binary(msg), do: msg
  defp format_error({msg, _opts}) when is_atom(msg), do: msg |> Atom.to_string() |> String.replace("_", " ")
  defp format_error(msg) when is_binary(msg), do: msg
  defp format_error(msg) when is_atom(msg), do: msg |> Atom.to_string() |> String.replace("_", " ")
end
