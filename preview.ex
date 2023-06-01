defmodule GameAdminFlaskWeb.Components.CategoryGroups.Preview do
  use GameAdminFlaskWeb, :stateful_component

  alias Moon.Assets.Icons.IconCloseSmall
  alias Moon.Assets.Icons.IconPencil
  alias Moon.Autolayouts.LeftToRight
  alias Moon.Autolayouts.PullAside

  alias Moon.Components.Button
  alias Moon.Components.Deprecated.TextInput
  alias Moon.Components.ErrorTag
  alias Moon.Components.Select.MultiSelect
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

  prop(selected_games, :list, default: [])
  prop(selected, :list, default: [])
  prop(selected_game_indexes, :list, default: [])

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        selected: [],
        selected_games: []
      )

    {:ok, socket}
  end

  def render(assigns) do
    IO.inspect(assigns.selected_games, label: "Selected Games in render")
    IO.inspect(assigns.selected, label: "Selected in render")
    ~F"""
    <SlideOver on_close={@on_close}>
      <:heading>Update for <strong>{@uid}</strong>
      </:heading>
      <:content>
        <LeftToRight>
          <Form id="update_category_group_form" class="flex-1" for={@changeset} change={@on_change}>
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

            <!-- NEW TEST DROPDOWN FORM -->
            <Form.Field field={:game_ids} label="Games" hint="Select games" class= "opacity-1">
              <Form.Dropdown
                is_multiple
                options={Enum.map(@games, &%{key: &1.label, value: String.to_integer(&1.value)})}
                prompt="Select Games"
                is_open={Map.get(assigns, :target, []) === ["create_or_update_category_group", "game_ids"]}
              />
            </Form.Field>

            <Form.Field class="basis-2/4 mb-2" field={:category_ids} label="Categories">
              <MultiSelect
                id="category_ids"
                options={@categories}
                prompt="Pick Categories"
                selected_label_text_color_class="text-goten"
              />
              <ErrorTag />
            </Form.Field>
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

        <!-- MOON TABLE -->
        <MoonTable items={game <- @selected_games} row_click="single_row_click" {=@selected}>
          <Column name="actions" label="Actions">
            <Button {:on_click, move_up_event(game.value)} disabled={is_first_game(game.value, @selected_games)}>
              Up
            </Button>
            <Button {:on_click, move_down_event(game.value)} disabled={is_last_game(game.value, @selected_games)}>
              Down
            </Button>
          </Column>
          <Column name="value" label="Game Value">
            {game.value}
          </Column>
          <Column name="label" label="Game Label">
            {game.label}
          </Column>
        </MoonTable>


      </:content>
    </SlideOver>
    """
  end

  def handle_event("single_row_click", %{"selected" => selected}, socket) do
    {:noreply, assign(socket, selected: [selected])}
  end

  ##  Event Handlers for the Up and Down Buttons
  def handle_event("move_up", %{"id" => game_id}, socket) do
    IO.inspect(game_id, label: "Game ID in move_up_event")
    index = Enum.find_index(socket.assigns.selected_games, &(&1.value == game_id))
    IO.inspect(index, label: "Index of Game ID in move_up_event")
    updated_games = swap_elements(socket.assigns.selected_games, index, index - 1)
    {:noreply, assign(socket, selected_games: updated_games)}
  end

  def handle_event("move_down", %{"id" => game_id}, socket) do
    IO.inspect(game_id, label: "Game ID in move_down_event")
    index = Enum.find_index(socket.assigns.selected_games, &(&1.value == game_id))
    IO.inspect(index, label: "Index of Game ID in move_down_event")
    updated_games = swap_elements(socket.assigns.selected_games, index, index + 1)
    {:noreply, assign(socket, selected_games: updated_games)}
  end

  ## Disable the Up and Down Buttons for the First and Last Games
  defp is_first_game(game_id, selected_games) do
    game_id == hd(selected_games).value
  end

  defp is_last_game(game_id, selected_games) do
    game_id == List.last(selected_games).value
  end

  defp swap_elements(list, index1, index2) do
    [elem1, elem2] = [Enum.at(list, index1), Enum.at(list, index2)]
    IO.inspect([elem1, elem2], label: "Elements to Swap in swap_elements")
    list
    |> List.replace_at(index1, elem2)
    |> List.replace_at(index2, elem1)
  end

  defp move_up_event(game_id) do
    # IO.inspect(game_id, label: "Game ID in move_up_event")
    {"move_up", %{id: game_id}}
  end

  defp move_down_event(game_id) do
    # IO.inspect(game_id, label: "Game ID in move_down_event")
    {"move_down", %{id: game_id}}
  end


  # defp update_category_group_game_ids(socket, %{assigns: %{update_changeset: changeset, auth: auth, selected_games: selected_games}}) do
  #   game_ids = Enum.map(selected_games, & &1.id)
  #   changeset = Changeset.change(changeset, %{game_ids: game_ids})
  #   case CreateOrUpdateCategoryGroup.update(changeset, auth) do
  #     {:ok, _id} -> socket
  #     {:error, changeset} -> assign(socket, update_changeset: changeset)
  #   end
  # end
end
