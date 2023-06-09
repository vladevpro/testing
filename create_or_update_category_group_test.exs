defmodule GameAdminFlask.Actions.CreateOrUpdateCategoryGroupTest do
  use GameAdminFlask.DataCase, async: true
  use LabFlask.Reaction.GameInventory

  require CreateCategoryGroupReaction.Response.Error.Kind.Items, as: CreateCategoryGroupError
  require UpdateCategoryGroupReaction.Response.Error.Kind.Items, as: UpdateCategoryGroupError

  import Mock

  alias GameAdminFlask.Actions.CreateOrUpdateCategoryGroup

  @context %{session_token: "token", operator_id: 1, site_ids: [1]}

  describe "changeset/2" do
    test "should validate required params" do
      %Ecto.Changeset{valid?: false} = changeset = CreateOrUpdateCategoryGroup.changeset()

      assert %{name: ["can't be blank"], site_id: ["can't be blank"], uid: ["can't be blank"]} = errors_on(changeset)
    end

    test "should validate types" do
      %Ecto.Changeset{valid?: false} =
        changeset = CreateOrUpdateCategoryGroup.changeset(%CreateOrUpdateCategoryGroup{}, %{"site_id" => "ID"})

      assert %{site_id: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "insert/2" do
    test "should reject invalid attributes" do
      assert {:error, %Ecto.Changeset{valid?: false}} =
               CreateOrUpdateCategoryGroup.insert(CreateOrUpdateCategoryGroup.changeset(), [])
    end
  end

  test "should call GameInventory and create a CategoryGroup" do
    assert {:ok, _} =
             %CreateOrUpdateCategoryGroup{
               name: "CategoryGroup name",
               uid: "CategoryGroup UID",
               site_id: 1
             }
             |> CreateOrUpdateCategoryGroup.changeset()
             |> CreateOrUpdateCategoryGroup.insert(@context)
  end

  test "should not create a CategoryGroup with invalid site_id" do
    with_mock GameAdminFlask.Test.SubstanceMocks.GameInventory.Reaction,
      create_category_group: fn _, _params ->
        CreateCategoryGroupReaction.error(site_id: CreateCategoryGroupError.invalid())
      end do
      assert {:error, changeset} =
               %CreateOrUpdateCategoryGroup{
                 name: "CategoryGroup name",
                 uid: "CategoryGroup UID",
                 site_id: 1
               }
               |> CreateOrUpdateCategoryGroup.changeset()
               |> CreateOrUpdateCategoryGroup.insert(@context)

      assert %{category_ids: [message]} = errors_on(changeset)
      assert message =~ "site_id: :INVALID"
    end
  end

  describe "update/2" do
    test "should reject invalid attributes" do
      assert {:error, %Ecto.Changeset{valid?: false}} =
               CreateOrUpdateCategoryGroup.update(CreateOrUpdateCategoryGroup.changeset(), [])
    end

    test "should call GameInventory and update a CategoryGroup" do
      assert {:ok, _} =
               %CreateOrUpdateCategoryGroup{
                 name: "CategoryGroup name",
                 uid: "CategoryGroup UID",
                 site_id: 1
               }
               |> CreateOrUpdateCategoryGroup.changeset()
               |> CreateOrUpdateCategoryGroup.update(@context)
    end
  end

  test "should call GameInventory but not update a CategoryGroup" do
    with_mock GameAdminFlask.Test.SubstanceMocks.GameInventory.Reaction,
      update_category_group: fn _, _params ->
        UpdateCategoryGroupReaction.error(id: UpdateCategoryGroupError.not_found())
      end do
      assert {:error, changeset} =
               %CreateOrUpdateCategoryGroup{
                 name: "CategoryGroup name",
                 uid: "CategoryGroup UID",
                 site_id: 1
               }
               |> CreateOrUpdateCategoryGroup.changeset()
               |> CreateOrUpdateCategoryGroup.update(@context)

      assert %{category_ids: [message]} = errors_on(changeset)
      assert message =~ "id: :NOT_FOUND"
    end
  end
end
