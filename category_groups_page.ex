defmodule GameAdminFlaskWeb.CategoryGroupsPage do
  @moduledoc """
  Category Groups
  """
  use GameAdminFlaskWeb, :live_view
  use LabFlask.Element.GameInventory

  alias BackofficeBase.Components.Table
  alias BackofficeBase.Components.UserMenu
  alias GameAdminFlask.Actions.CreateOrUpdateCategoryGroup
  alias GameAdminFlask.Data.CategoryGroups
  alias GameAdminFlask.Data.GameCategories
  alias GameAdminFlask.Data.GameInventory
  alias GameAdminFlask.Data.Sites
  alias GameAdminFlaskWeb.Components.CategoryGroups.Create
  alias GameAdminFlaskWeb.Components.CategoryGroups.Preview
  alias GameAdminFlaskWeb.Components.LeftMenu
  alias Moon.Assets.Icons.IconAdd
  alias Moon.Autolayouts.ButtonsList
  alias Moon.Autolayouts.LeftToRight
  alias Moon.Autolayouts.TopToDown
  alias Moon.Components.Button
  alias Moon.Components.Heading

  @default_page_count 10

  data(category_groups, :list, default: [])
  data(sort_by, :tuple, default: {:id, :ASC})
  data(page, :integer, default: 1)
  data(page_count, :integer, default: @default_page_count)
  data(default_page_count, :integer, default: @default_page_count)
  data(total_count, :integer, default: 0)
  data(create_changeset, :changeset, default: nil)
  data(update_changeset, :changeset, default: nil)
  data(uid, :changeset, default: nil)
  data(active_category_group, :map, default: %{id: nil})
  data(target, :list, default: [])

  def render(assigns) do
    ~F"""
    <div class="min-h-screen bg-goku">
      <UserMenu id="user-menu" auth={@auth} />
      <LeftToRight gap="gap-0">
        <LeftMenu id="left-menu" current_item={%{id: 3, name: "Category Groups"}} />
        <TopToDown class="min-w-0 py-8 grow" gap="gap-4">
          <Heading size={32}>Category Groups</Heading>
          <ButtonsList class="pr-6">
            <Button variant="secondary" on_click="open_create">
              <:left_icon_slot><IconAdd /></:left_icon_slot>
              Create
            </Button>
          </ButtonsList>
          <Table
            id="category_groups_table"
            columns={[
              %{label: "ID", field: :id, sortable: true, size: 16},
              %{label: "UID", field: :uid, size: 48},
              %{label: "Name", field: :name, size: 48},
              %{label: "Site", field: :site, type: :uid, size: 48},
              %{label: "Created At", field: :inserted_at, type: :datetime_relative, size: 48},
              %{label: "Updated At", field: :updated_at, type: :datetime_relative, size: 48}
            ]}
            items={@category_groups}
            active_item_id={@active_category_group.id}
            sort_by={@sort_by}
            page={@page}
            page_count={10}
            total_count={nil}
          />
        </TopToDown>
      </LeftToRight>
    </div>
    {#if @active_category_group.id != nil}
      <div :on-click="close_update" class="fixed inset-0 z-20" />
      <Preview
        id="category_group-preview"
        changeset={@update_changeset}
        uid={@uid}
        on_close="close_update"
        on_submit="on_submit_update"
        on_change="on_change_update"
        categories={@categories}
        games={@games}
        sites={@sites}
        target={@target}
      />
    {/if}
    <Create
      :if={is_create_open?(@create_changeset)}
      changeset={@create_changeset}
      on_close="close_create"
      on_change="on_change_create"
      on_submit="on_submit_create"
      categories={@categories}
      games={@games}
      sites={@sites}
    />
    """
  end

  def mount(_params, _session, %{assigns: %{auth: auth}} = socket) do
    socket =
      socket
      |> assign_category_groups()
      |> assign(
        games: load_games(auth),
        categories: load_categories(auth),
        sites: load_sites(auth),
        create_changeset: nil
      )

    {:ok, socket}
  end

  def load_category_groups(%{
        assigns: %{
          sort_by: {sort_field, sort_direction},
          page: page,
          auth: auth
        }
      }) do
    CategoryGroups.load(
      [
        sort:
          struct(CategoryGroupElement.Sort, %{
            sort_field => sort_direction
          }),
        pagination: %LabFlask.Proto.Lab.Global.Pagination{
          limit: page * @default_page_count,
          offset: (page - 1) * @default_page_count
        }
      ],
      auth
    )
  end

  #
  # Message Handler
  #

  def handle_info({:table, {"category_groups_table", :select, category_group}}, socket) do
    socket =
      socket
      |> assign(update_changeset: changeset_for_update(category_group))
      |> assign(uid: category_group.uid)
      |> assign(active_category_group: category_group)

    {:noreply, socket}
  end

  def handle_info({:table, {"category_groups_table", :refresh}}, socket),
    do: {:noreply, assign_category_groups(socket)}

  def handle_info({:table, {"category_groups_table", :sort, sort_by}}, socket) do
    socket =
      socket
      |> assign(sort_by: sort_by, page: 1)
      |> assign_category_groups()

    {:noreply, socket}
  end

  def handle_info(
        {:table, {"category_groups_table", :paginate, next_page}},
        %{assigns: %{page: current_page, page_count: page_count}} = socket
      ) do
    socket =
      if next_page <= current_page or page_count == @default_page_count do
        socket
        |> assign(page: next_page)
        |> assign_category_groups()
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({"update_changeset", changeset}, socket) do
    {:noreply, assign(socket, update_changeset: changeset, target: false)}
  end

  defp changeset_for_update(%{
         id: id,
         uid: uid,
         name: name,
         game_ids: game_ids,
         category_ids: category_ids,
         site: %{id: site_id}
       }) do
    %{
      CreateOrUpdateCategoryGroup.changeset(
        %CreateOrUpdateCategoryGroup{id: id},
        %{
          "uid" => uid,
          "name" => name,
          "site_id" => site_id,
          "game_ids" => game_ids,
          "category_ids" => category_ids
        }
      )
      | action: :update
    }
  end

  def handle_event("goto_prev_page", _, %{assigns: %{page: page}} = socket) do
    socket =
      if page > 1,
        do: assign_category_groups_by_page(socket, page - 1),
        else: socket

    {:noreply, socket}
  end

  def handle_event(
        "goto_next_page",
        _,
        %{assigns: %{page: page, total_count: total_count}} = socket
      ) do
    socket =
      if (page + 1) * @default_page_count < total_count + @default_page_count,
        do: assign_category_groups_by_page(socket, page + 1),
        else: socket

    {:noreply, socket}
  end

  def handle_event("open_create", _, socket),
    do: {:noreply, assign(socket, create_changeset: CreateOrUpdateCategoryGroup.changeset())}

  def handle_event("close_create", _, socket),
    do: {:noreply, assign(socket, create_changeset: nil)}

  def handle_event(
        "on_change_create",
        %{"create_or_update_category_group" => changeset},
        socket
      ) do
    {:noreply,
     assign(socket,
       create_changeset: CreateOrUpdateCategoryGroup.changeset(%CreateOrUpdateCategoryGroup{}, changeset)
     )}
  end

  def handle_event(
        "on_submit_create",
        _,
        %{
          assigns: %{
            auth: auth,
            create_changeset: changeset
          }
        } = socket
      ) do
    case CreateOrUpdateCategoryGroup.insert(changeset, auth) do
      {:ok, _id} ->
        {
          :noreply,
          socket
          |> assign(create_changeset: nil)
          |> assign_category_groups()
        }

      {:error, changeset} ->
        {:noreply, assign(socket, create_changeset: changeset)}
    end
  end

  def handle_event(
        "on_change_update",
        %{"create_or_update_category_group" => changeset} = params,
        %{assigns: %{update_changeset: update_changeset}} = socket
      ) do
    target =
      if Map.get(params, "action") not in [:button_click, :row_select] do
        Map.get(params, "_target", [])
      else
        []
      end

    {:noreply,
     assign(socket,
       target: target,
       update_changeset:
         CreateOrUpdateCategoryGroup.changeset(
           %{update_changeset | errors: [], valid?: true},
           changeset
         )
     )}
  end

  def handle_event(
        "on_submit_update",
        _,
        %{
          assigns: %{
            auth: auth,
            update_changeset: changeset
          }
        } = socket
      ) do
    case CreateOrUpdateCategoryGroup.update(changeset, auth) do
      {:ok, _id} ->
        {
          :noreply,
          socket
          |> assign(active_category_group: %{id: nil}, update_changeset: nil, uid: nil, target: false)
          |> assign_category_groups()
        }

      {:error, changeset} ->
        {:noreply, assign(socket, update_changeset: changeset)}
    end
  end

  def handle_event("close_update", _, socket) do
    {:noreply, assign(socket, active_category_group: %{id: nil}, update_changeset: nil, uid: nil)}
  end

  defp assign_category_groups_by_page(socket, page) do
    socket
    |> assign(page: page)
    |> assign_category_groups()
  end

  defp assign_category_groups(socket) do
    category_groups = load_category_groups(socket)

    assign(socket,
      category_groups: category_groups,
      page_count: length(category_groups)
    )
  end

  defp is_create_open?(nil), do: false
  defp is_create_open?(_), do: true

  defp load_games(auth) do
    GameInventory.load_for_category_group(auth)
    |> Enum.map(&%{label: "#{&1.id} #{&1.name}", value: Integer.to_string(&1.id)})
  end

  defp load_categories(auth) do
    GameCategories.load([], auth)
    |> Enum.map(&%{label: "#{&1.id} #{&1.name}", value: Integer.to_string(&1.id)})
  end

  defp load_sites(auth) do
    Sites.load([], auth)
    |> Enum.map(&%{key: "#{&1.id} #{&1.uid}", value: Integer.to_string(&1.id)})
  end
end
