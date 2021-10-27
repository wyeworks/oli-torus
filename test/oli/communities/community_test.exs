defmodule Oli.Communities.CommunityTest do
  use Oli.DataCase

  import Oli.Factory

  alias Oli.Communities.Community

  describe "community" do
    test "changeset should be invalid if name is empty" do
      changeset = build(:community, %{name: ""})
        |> Community.changeset()

      refute changeset.valid?
    end

    test "create community with valid data creates a community" do
      assert {:ok, %Community{} = community} =
        Community.create_community(%{
          name: "Testing name",
          description: "Testing description",
          key_contact: "Testing key contact"})

      assert community.name == "Testing name"
      assert community.description == "Testing description"
      assert community.key_contact == "Testing key contact"
    end

    test "create community with existing name returns error changeset" do
      insert(:community, %{name: "Testing"})

      assert {:error, %Ecto.Changeset{}}
        = Community.create_community(%{name: "Testing"})
    end

    test "list communities returns ok when there are no communities" do
      assert [] = Community.list_communities()
    end

    test "list communities returns all the communities" do
      insert_list(3, :community)

      assert 3 = length(Community.list_communities())
    end
  end
end
