defmodule Oli.Factory do
  alias Oli.Repo
  alias Oli.Communities.Community

  # Factories

  def build(:community) do
    %Community{
      name: "Example community #{System.unique_integer([:positive])}",
      description: "An awesome description",
      key_contact: "keycontact@example.com"
    }
  end

  # API

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  def bulk_insert!(factory_name, count) do
    for _i <- 1..count, do: insert!(factory_name)
  end
end
