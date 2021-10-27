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

  describe "find/1" do
    test "returns a community when the id exists" do
      community = insert(:community)

      returned_community = Community.find(community.id)

      assert community.id == returned_community.id
      assert community.name == returned_community.name
    end

    test "returns nil if the community does not exist" do
      assert nil == Community.find(123)
    end
  end

  describe "update/2" do
    setup do
      community = insert(:community)

      {:ok, [community: community]}
    end

    test "updates the community successfully", %{community: community} do
      {:ok, updated_community} = Community.update(community, %{name: "new_name"})

      assert community.id == updated_community.id
      assert updated_community.name == "new_name"
    end

    test "does not update the community when there is an invalid field", %{community: community} do
      another_community = insert(:community)

      {:error, changeset} = Community.update(community, %{name: another_community.name})
      {error, _} = changeset.errors[:name]

      refute changeset.valid?
      assert error =~ "has already been taken"
    end
  end
end
