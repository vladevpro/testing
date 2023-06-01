defmodule GameAdminFlask.Actions.CreateOrUpdateCategoryGroup do
  use Ecto.Schema
  use GameAdminFlask.Flask
  use LabFlask.Reaction.GameInventory

  require Logger

  import Ecto.Changeset

  @default_values %{"game_ids" => [], "category_ids" => []}

  @required_fields ~w(uid name site_id game_ids category_ids)a

  embedded_schema do
    field(:uid, :string)
    field(:name, :string)
    field(:site_id, :integer)
    field(:game_ids, {:array, :integer}, default: [])
    field(:category_ids, {:array, :integer}, default: [])
  end

  # TODO: Add validations for filling one of:
  # game_ids OR category_ids at least.
  def changeset(data \\ %__MODULE__{}, params \\ %{}) do
    data
    |> cast(Map.merge(@default_values, params), @required_fields)
    |> validate_required(@required_fields)
  end

  @spec insert(Ecto.Changeset.t(), map()) :: {:ok, pos_integer()} | {:error, Ecto.Changeset.t()}
  def insert(changeset, auth) do
    case apply_action(changeset, :insert) do
      {:ok, data} -> create_category_group(changeset, data, auth)
      {:error, _changeset} = error -> error
    end
  end

  defp create_category_group(changeset, data, auth) do
    request = %CreateCategoryGroupReaction.Request{
      name: data.name,
      uid: data.uid,
      site_id: data.site_id,
      game_ids: data.game_ids,
      category_ids: data.category_ids
    }

    request
    |> GameInventoryReactionAPI.create_category_group(LabAuth.Context.reaction_context(auth))
    |> case do
      {:ok, CreateCategoryGroupReaction.ok(id: category_group)} ->
        {:ok, category_group}

      {:ok, CreateCategoryGroupReaction.error(uid: :ALREADY_EXISTS)} ->
        {:error, add_error(changeset, :uid, "Already exists.")}

      {:ok, CreateCategoryGroupReaction.error(name: :ALREADY_EXISTS)} ->
        {:error, add_error(changeset, :name, "Already exists.")}

      error ->
        Logger.error("error: #{inspect(error)}, for request: #{inspect(request)}")
        {:error, add_error(changeset, :category_ids, "Something went wrong. #{inspect(error)}")}
    end
  end

  @spec update(Ecto.Changeset.t(), map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def update(changeset, auth) do
    case apply_action(changeset, :update) do
      {:ok, data} -> update_category_group(changeset, data, auth)
      {:error, _changeset} = error -> error
    end
  end

  defp update_category_group(changeset, data, auth) do
    request = %UpdateCategoryGroupReaction.Request{
      id: data.id,
      name: data.name,
      uid: data.uid,
      game_ids: data.game_ids,
      category_ids: data.category_ids
    }

    request
    |> GameInventoryReactionAPI.update_category_group(LabAuth.Context.reaction_context(auth))
    |> case do
      {:ok, UpdateCategoryGroupReaction.ok(id: category_group)} ->
        {:ok, category_group}

      {:ok, UpdateCategoryGroupReaction.error(uid: :ALREADY_EXISTS)} ->
        {:error, add_error(changeset, :uid, "Already exists.")}

      {:ok, UpdateCategoryGroupReaction.error(name: :ALREADY_EXISTS)} ->
        {:error, add_error(changeset, :name, "Already exists.")}

      error ->
        Logger.error("error: #{inspect(error)}, for request: #{inspect(request)}")
        {:error, add_error(changeset, :category_ids, "Something went wrong. #{inspect(error)}")}
    end
  end
end
