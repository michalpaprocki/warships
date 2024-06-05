defmodule WarshipsWeb.Home.FormData do
  alias Ecto.Changeset
  @types %{name: :string, password: :string}

  def validate(params) do
    {%{}, @types}
    |> Changeset.cast(params, Map.keys(@types))
    |> Changeset.validate_required(:name)
    |> Changeset.validate_length(:name, min: 3)
    |> Changeset.validate_length(:password, min: 5)
    |> Map.put(:action, :validate)
  end
end
