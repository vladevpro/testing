defmodule GameAdminFlaskWeb.Components.CategoryGroups.Preview do
  use GameAdminFlaskWeb, :stateful_component

  alias GameAdminFlask.Actions.CreateOrUpdateCategoryGroup
  alias Moon.Assets.Icons.IconArrowDown
  alias Moon.Assets.Icons.IconArrowUp
  alias Moon.Assets.Icons.IconCloseSmall
  alias Moon.Assets.Icons.IconPencil
  alias Moon.Autolayouts.LeftToRight
  alias Moon.Autolayouts.PullAside

  alias Moon.Components.Button
  alias Moon.Components.Deprecated.TextInput
  alias Moon.Components.ErrorTag
  alias Moon.Components.SlideOver
  alias Moon.Design.Form

  alias Moon.Design.Table, as: MoonTable
  alias Moon.Design.Table.Column

  prop(changeset, :changeset, required: true)
  prop(games, :list, required: true)
  prop(categories, :list, required: true)
  prop(sites, :list, required: true)
  prop(uid, :string, required: true)
  prop(target, :string, required: true)

  prop(on_close, :event, required: true)
  prop(on_change, :event, required: true)
  prop(on_submit, :event, required: true)
  prop(on_select, :event)

  data(selected_games, :any)
  data(selected_categories, :any)

  def update(updates, socket) do
    socket =
      socket
      |> assign(updates)

    %{games: games, categories: categories, changeset: changeset} = socket.assigns

    # Handling game_ids.
    game_ids =
      case changeset do
        %{changes: %{game_ids: game_ids}} ->
          game_ids

        _ ->
          []
      end

    selected_games =
      game_ids
      |> Enum.map(fn game_id -> Enum.find(games, &(&1.value == to_string(game_id))) end)
      |> Enum.reject(&is_nil/1)

    # Handling category_ids.
    category_ids =
      case changeset do
        %{changes: %{category_ids: category_ids}} ->
          category_ids

        _ ->
          []
      end

    selected_categories =
      category_ids
      |> Enum.map(fn category_id -> Enum.find(categories, &(&1.value == to_string(category_id))) end)
      |> Enum.reject(&is_nil/1)

    socket =
      assign(socket,
        selected_games: selected_games,
        selected_categories: selected_categories
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <SlideOver on_close={@on_close}>
      <:heading>Update for <strong>{@uid}</strong>
      </:heading>
      <:content>
        <LeftToRight>
          <Form id="update_category_group_form" class="flex flex-col flex-1 gap-3" for={@changeset} change={@on_change}>
            <LeftToRight>
              <Form.Field class="basis-2/4 mb-2" field={:site_id} label="Site">
                <Form.Select options={@sites} prompt="Select Site" class="w-full bg-goku" size="lg" disabled />
                <ErrorTag />
              </Form.Field>
            </LeftToRight>
            <LeftToRight>
              <Form.Field class="basis-2/4 mb-2" field={:uid} label="UID">
                <TextInput placeholder="UID" background_color="gohan" />
                <ErrorTag />
              </Form.Field>
              <Form.Field class="basis-2/4 mb-2" field={:name} label="Name">
                <TextInput placeholder="Name" background_color="gohan" />
                <ErrorTag />
              </Form.Field>
            </LeftToRight>

            <!-- Games DROPDOWN FORM -->
            <Form.Field field={:game_ids} label="Games"  class= "opacity-1">
              <Form.Dropdown
                id="game_dropdown"
                is_multiple
                options={Enum.map(@games, &%{key: &1.label, value: String.to_integer(&1.value)})}
                prompt="Select Games"
                is_open={Map.get(assigns, :target, []) === ["create_or_update_category_group", "game_ids"]}
              />
            </Form.Field>

            <!-- Games TABLE -->
            <MoonTable id="game_table" items={game <- @selected_games}>
              <Column name="actions" label="Actions">
                  <LeftToRight>
                  <Button on_click={move_up_event(game.id)} disabled={game.value == hd(@selected_games).value}>
                  <:left_icon_slot><IconArrowUp /></:left_icon_slot>
                  </Button>
                  <Button on_click={move_down_event(game.id)} disabled={game.value == List.last(@selected_games).value}>
                  <:left_icon_slot><IconArrowDown /></:left_icon_slot>
                  </Button>
                </LeftToRight>
              </Column>
              <Column name="value" label="Game Value">
                {game.value}
              </Column>
              <Column name="label" label="Game Label">
                {game.label}
              </Column>
            </MoonTable>

            <!-- Categories DROPDOWN FORM -->
              <Form.Field field={:category_ids} label="Categories"  class= "opacity-1">
              <Form.Dropdown
                id="category_dropdown"
                is_multiple
                options={Enum.map(@categories, &%{key: &1.label, value: String.to_integer(&1.value)})}
                prompt="Pick Categories"
                is_open={Map.get(assigns, :target, []) === ["create_or_update_category_group", "category_ids"]}
              />
            </Form.Field>

            <!-- Categories TABLE -->
            <MoonTable id="category_table" items={category <- @selected_categories}>
              <Column name="actions" label="Actions">
                  <LeftToRight>
                  <Button on_click={move_up_event_category(category.id)} disabled={category.value == hd(@selected_categories).value}>
                  <:left_icon_slot><IconArrowUp /></:left_icon_slot>
                  </Button>
                  <Button on_click={move_down_event_category(category.id)} disabled={category.value == List.last(@selected_categories).value}>
                  <:left_icon_slot><IconArrowDown /></:left_icon_slot>
                  </Button>
                </LeftToRight>
              </Column>
              <Column name="value" label="Category Value">
                {category.value}
              </Column>
              <Column name="label" label="Category Label">
                {category.label}
              </Column>
            </MoonTable>

          </Form>
        </LeftToRight>

        <PullAside class="mt-8">
        <:right>
          <LeftToRight>
            <Button variant="secondary" on_click={@on_close}>
              <:left_icon_slot><IconCloseSmall /></:left_icon_slot>
              Close
            </Button>
            <Button on_click={@on_submit} disabled={!@changeset.valid?}>
              <:left_icon_slot><IconPencil /></:left_icon_slot>
              Update
            </Button>
          </LeftToRight>
        </:right>
      </PullAside>

      </:content>
    </SlideOver>
    """
  end

  ##  Event Handlers for the Up and Down Buttons for Games
  def handle_event("move_up:" <> index, _params, socket) do
    %{changes: changes} = changeset = socket.assigns.changeset
    index = String.to_integer(index)

    game_ids = Map.get(changes, :game_ids, [])
    category_ids = Map.get(changes, :category_ids, [])
    name = Map.get(changes, :name, "")

    updated_game_ids =
      game_ids
      |> List.replace_at(index, Enum.at(game_ids, index - 1))
      |> List.replace_at(index - 1, Enum.at(game_ids, index))

    # category_ids added
    updated_changeset =
      CreateOrUpdateCategoryGroup.changeset(changeset, %{
        "game_ids" => updated_game_ids,
        "category_ids" => category_ids,
        "name" => name
      })

    send(self(), {"update_changeset", updated_changeset})
    {:noreply, assign(socket, changeset: updated_changeset)}
  end

  def handle_event("move_down:" <> index, _params, socket) do
    %{changes: changes} = changeset = socket.assigns.changeset
    index = String.to_integer(index)

    game_ids = Map.get(changes, :game_ids, [])
    category_ids = Map.get(changes, :category_ids, [])
    name = Map.get(changes, :name, "")

    updated_game_ids =
      game_ids
      |> List.replace_at(index, Enum.at(game_ids, index + 1))
      |> List.replace_at(index + 1, Enum.at(game_ids, index))

    updated_changeset =
      CreateOrUpdateCategoryGroup.changeset(changeset, %{
        "game_ids" => updated_game_ids,
        "category_ids" => category_ids,
        "name" => name
      })

    send(self(), {"update_changeset", updated_changeset})
    {:noreply, assign(socket, changeset: updated_changeset)}
  end

  ##  Event Handlers for the Up and Down Buttons for Categories
  def handle_event("move_up_category:" <> index, _params, socket) do
    %{changes: changes} = changeset = socket.assigns.changeset
    index = String.to_integer(index)

    game_ids = Map.get(changes, :game_ids, [])
    category_ids = Map.get(changes, :category_ids, [])
    name = Map.get(changes, :name, "")

    updated_category_ids =
      category_ids
      |> List.replace_at(index, Enum.at(category_ids, index - 1))
      |> List.replace_at(index - 1, Enum.at(category_ids, index))

    updated_changeset =
      CreateOrUpdateCategoryGroup.changeset(changeset, %{
        "game_ids" => game_ids,
        "category_ids" => updated_category_ids,
        "name" => name
      })

    send(self(), {"update_changeset", updated_changeset})
    {:noreply, assign(socket, changeset: updated_changeset)}
  end

  def handle_event("move_down_category:" <> index, _params, socket) do
    %{changes: changes} = changeset = socket.assigns.changeset
    index = String.to_integer(index)

    game_ids = Map.get(changes, :game_ids, [])
    category_ids = Map.get(changes, :category_ids, [])
    name = Map.get(changes, :name, "")

    updated_category_ids =
      category_ids
      |> List.replace_at(index, Enum.at(category_ids, index + 1))
      |> List.replace_at(index + 1, Enum.at(category_ids, index))

    # game_ids added
    updated_changeset =
      CreateOrUpdateCategoryGroup.changeset(changeset, %{
        "game_ids" => game_ids,
        "category_ids" => updated_category_ids,
        "name" => name
      })

    send(self(), {"update_changeset", updated_changeset})
    {:noreply, assign(socket, changeset: updated_changeset)}
  end

  ## Helper functions for the move up and down events
  defp move_up_event(game_id) do
    "move_up:#{game_id}"
  end

  defp move_down_event(game_id) do
    "move_down:#{game_id}"
  end

  defp move_up_event_category(category_id) do
    "move_up_category:#{category_id}"
  end

  defp move_down_event_category(category_id) do
    "move_down_category:#{category_id}"
  end
end
