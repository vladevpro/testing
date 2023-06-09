defmodule GameAdminFlaskWeb.CategoryGroupsPageTest do
  use GameAdminFlaskWeb.ConnCase

  import Phoenix.LiveViewTest

  alias GameAdminFlaskWeb.CategoryGroupsPage

  describe "redirect" do
    test "should redirect to login page when not authenticated", %{conn: conn} do
      conn = get(conn, Routes.live_path(conn, CategoryGroupsPage))

      assert redirected_to(conn) =~ "http://localhost:4018/login?return_path=/category_groups&return_flask=game_admin"
    end
  end

  describe "render" do
    setup :login_and_add_user_agent

    setup_with_mocks(
      [
        {LabAuth, [],
         [
           verify_token: fn _, _ ->
             {:ok, %{"iss" => "operator1", "aud" => nil, "sub" => "testuser", "subId" => 1}}
           end
         ]}
      ],
      %{conn: conn}
    ) do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, CategoryGroupsPage))

      {:ok, conn: conn, view: view}
    end

    test "should render basic components", %{view: view} do
      render(view) =~ "Category Groups"

      assert has_element?(view, "table")
      assert has_element?(view, "button", "Create")
    end

    test "should open Create popup", %{view: view} do
      view
      |> element("button", "Create")
      |> render_click()

      assert has_element?(view, "button", "Discard")
      assert has_element?(view, "button", "Create")

      assert render(view) =~ "Create a new Category Group"
    end

    test "should discard Create popup", %{view: view} do
      view
      |> element("button", "Create")
      |> render_click()

      view
      |> element("button", "Discard")
      |> render_click()

      refute has_element?(view, "button", "Discard")
      refute render(view) =~ "Create a new Category Group"
    end

    test "should close Create popup", %{view: view} do
      view
      |> element("button", "Create")
      |> render_click()

      view
      |> element("button[phx-click=\"close_create\"]")
      |> render_click()

      refute has_element?(view, "button", "Discard")
    end
  end

  describe "create" do
    setup :login_and_add_user_agent

    setup_with_mocks(
      [
        {LabAuth, [],
         [
           verify_token: fn _, _ ->
             {:ok, %{"iss" => "operator1", "aud" => nil, "sub" => "testuser", "subId" => 1}}
           end
         ]}
      ],
      %{conn: conn}
    ) do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, CategoryGroupsPage))

      {:ok, conn: conn, view: view}
    end

    test "should validate CategoryGroup attributes", %{view: view} do
      view
      |> element("button", "Create")
      |> render_click()

      assert view
             |> element("button[phx-click=\"on_submit_create\"]")
             |> render_click() =~
               "can&#39;t be blank"
    end

    test "should create a CategoryGroup", %{view: view} do
      view
      |> element("button", "Create")
      |> render_click()

      view
      |> form("form#create_category_group_form",
        create_or_update_category_group: %{
          site_id: 1,
          name: "My new CategoryGroup",
          uid: "UID"
        }
      )
      |> render_change()

      assert view
             |> form("form#create_category_group_form")
             |> render_submit()

      refute has_element?(view, "button", "Discard")
    end
  end

  describe "update" do
    setup :login_and_add_user_agent

    setup_with_mocks(
      [
        {LabAuth, [],
         [
           verify_token: fn _, _ ->
             {:ok, %{"iss" => "operator1", "aud" => nil, "sub" => "testuser", "subId" => 1}}
           end
         ]}
      ],
      %{conn: conn}
    ) do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, CategoryGroupsPage))

      {:ok, conn: conn, view: view}
    end

    test "should open a CategoryGroup preview", %{view: view} do

      view
      |> element("#category_groups_table-item-1")
      |> render_click()

      assert has_element?(view, "#update_category_group_form_name")
      assert has_element?(view, "#update_category_group_form_site_id")
      assert has_element?(view, "#game_dropdown-dropdown")
      assert has_element?(view, "#category_dropdown-dropdown")
      assert has_element?(view, "#game_table")
      assert has_element?(view, "#category_table")
      assert has_element?(view, "button", "Update")
      assert has_element?(view, "button", "Close")

      # Check for 'Form.Dropdown' for games and categories
      assert has_element?(view, "#game_dropdown-dropdown", "Select Games")
      assert has_element?(view, "#category_dropdown-dropdown", "Pick Categories")

      # Check for 'MoonTable' for games and categories
      assert has_element?(view, "#game_table", "Game Value")
      assert has_element?(view, "#game_table", "Game Label")
      assert has_element?(view, "#category_table", "Category Value")
      assert has_element?(view, "#category_table", "Category Label")

      view
      |> element("button", "Close")
      |> render_click()

      refute has_element?(view, "button", "Update")

      view
      |> element("#category_groups_table-item-1")
      |> render_click()

      assert has_element?(view, "button", "Update")

      view
      |> element("button[phx-click=\"close_update\"]")
      |> render_click()

      refute has_element?(view, "button", "Update")
    end

    test "should display dropdown forms for Games and Categories", %{view: view} do
      view
      |> element("#category_groups_table-item-1")
      |> render_click()

      assert has_element?(view, "#game_dropdown-dropdown", "Select Games")
      assert has_element?(view, "#category_dropdown-dropdown", "Pick Categories")
    end

    test "should display MoonTable for Games and Categories", %{view: view} do
      view
      |> element("#category_groups_table-item-1")
      |> render_click()

      assert has_element?(view, "#game_table", "Game Value")
      assert has_element?(view, "#game_table", "Game Label")
      assert has_element?(view, "#category_table", "Category Value")
      assert has_element?(view, "#category_table", "Category Label")
    end

    # test "should render up and down arrows", %{view: view} do
    #   assert has_element?(view, "button", "Up")
    #   assert has_element?(view, "button", "Down")
    # end

    test "should update a CategoryGroup", %{view: view} do
      view
      |> element("#category_groups_table-item-1")
      |> render_click()

      view
      |> form("form#update_category_group_form",
        create_or_update_category_group: %{
          uid: "my-newer-category-group",
          name: "My newer CategoryGroup"
        }
      )
      |> render_change()

      view
      |> element("button[phx-click=\"on_submit_update\"]")
      |> render_click()

      refute has_element?(view, "button", "Update")
    end

    test "should disable update button on an invalid changeset", %{view: view} do
      view
      |> element("#category_groups_table-item-1")
      |> render_click()

      refute has_element?(view, "button[disabled]")

      view
      |> form("form#update_category_group_form",
        create_or_update_category_group: %{
          name: ""
        }
      )
      |> render_change()

      assert has_element?(view, "button[disabled]")
    end
  end

  test "load_category_groups" do
    socket = %{
      assigns: %{
        sort_by: {:id, :ASC},
        page: 1,
        auth: %{session_token: nil, operator_id: 1, site_ids: [1]}
      }
    }

    assert CategoryGroupsPage.load_category_groups(socket) != []
  end
end
