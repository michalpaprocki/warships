defmodule WarshipsWeb.Nickname.FormData do
  alias Ecto.Changeset
  @types %{name: :string}
  def validate(params) do
    {%{}, @types}
    |> Changeset.cast(params, Map.keys(@types))
    |> Changeset.validate_required(:name)
    |> Changeset.validate_length(:name, min: 5)
    |> Map.put(:action, :validate)
  end
end
