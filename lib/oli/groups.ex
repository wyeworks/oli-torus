defmodule Oli.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false

  alias Oli.Accounts
  alias Oli.Accounts.Author
  alias Oli.Groups.Community
  alias Oli.Groups.CommunityAccount
  alias Oli.Repo

  @doc """
  Returns the list of communities.

  ## Examples

      iex> list_communities()
      [%Community{}, ...]

  """
  def list_communities, do: Repo.all(Community)

  @doc """
  Returns the list of communities that meets the criteria passed in the input.

  ## Examples

      iex> search_communities(%{status: :active})
      [%Community{status: :active}, ...]

      iex> search_communities(%{global_access: false})
      []
  """
  def search_communities(filter) do
    from(c in Community, where: ^filter_conditions(filter))
    |> Repo.all()
  end

  @doc """
  Creates a community.

  ## Examples

      iex> create_community(%{field: new_value})
      {:ok, %Community{}}

      iex> create_community(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_community(attrs \\ %{}) do
    %Community{}
    |> Community.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a community by id.

  ## Examples

      iex> get_community(1)
      %Community{}
      iex> get_community(123)
      nil
  """
  def get_community(id), do: Repo.get_by(Community, %{id: id, status: :active})

  @doc """
  Updates a community.

  ## Examples

      iex> update_community(community, %{name: new_value})
      {:ok, %Community{}}
      iex> update_community(community, %{name: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def update_community(%Community{} = community, attrs) do
    community
    |> Community.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a community.

  ## Examples

      iex> delete_community(community)
      {:ok, %Community{}}

      iex> delete_community(community)
      {:error, %Ecto.Changeset{}}

  """
  def delete_community(%Community{} = community) do
    update_community(community, %{status: :deleted})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking community changes.

  ## Examples

      iex> change_community(community)
      %Ecto.Changeset{data: %Community{}}

  """
  def change_community(%Community{} = community, attrs \\ %{}) do
    Community.changeset(community, attrs)
  end

  defp filter_conditions(filter) do
    Enum.reduce(filter, false, fn {field, value}, conditions ->
      dynamic([entity], field(entity, ^field) == ^value or ^conditions)
    end)
  end

  @doc """
  Creates a community account.

  ## Examples

      iex> create_community_account(%{field: new_value})
      {:ok, %CommunityAccount{}}

      iex> create_community_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_community_account(attrs \\ %{}) do
    %CommunityAccount{}
    |> CommunityAccount.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a community account from an author email (gets the author first).

  ## Examples

      iex> create_community_account_from_author_email("example@foo.com", %{field: new_value})
      {:ok, %CommunityAccount{}}

      iex> create_community_account_from_author_email("example@foo.com", %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_community_account_from_author_email(email, attrs \\ %{}) do
    case Accounts.get_author_by_email(email) do
      %Author{id: id} ->
        attrs |> Map.put(:author_id, id) |> create_community_account()

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets a community account by id.

  ## Examples

      iex> get_community_account(1)
      %CommunityAccount{}
      iex> get_community_account(123)
      nil
  """
  def get_community_account(id), do: Repo.get(CommunityAccount, id)

  @doc """
  Gets a community account by clauses.

  ## Examples

      iex> get_community_account_by(%{author_id: 1})
      %CommunityAccount{}
      iex> get_community_account_by(%{author_id: 123})
      nil
  """
  def get_community_account_by(clauses), do: Repo.get_by(CommunityAccount, clauses)

  @doc """
  Deletes a community account.

  ## Examples

      iex> delete_community_account(%{community_id: 1, author_id: 1})
      {:ok, %CommunityAccount{}}

      iex> delete_community_account(%{community_id: 1, author_id: bad})
      nil

  """
  def delete_community_account(clauses) do
    case get_community_account_by(clauses) do
      nil -> {:error, :not_found}
      community_account -> Repo.delete(community_account)
    end
  end

  @doc """
  Get all the admins for a specific community.

  ## Examples

      iex> list_community_admins(1)
      {:ok, [%Author{}, ...]}

      iex> list_community_admins(123)
      {:ok, []}
  """
  def list_community_admins(community_id) do
    Repo.all(
      from(
        community_account in CommunityAccount,
        join: author in Author,
        on: community_account.author_id == author.id,
        where:
          community_account.community_id == ^community_id and community_account.is_admin == true,
        select: author
      )
    )
  end

  @doc """
  Get all the communities for a specific admin.

  ## Examples

      iex> list_admin_communities(1)
      {:ok, [%Community{}, ...]}

      iex> list_admin_communities(123)
      {:ok, []}
  """
  def list_admin_communities(author_id) do
    Repo.all(
      from(
        community_account in CommunityAccount,
        join: community in Community,
        on: community_account.community_id == community.id,
        where: community_account.author_id == ^author_id and community_account.is_admin == true,
        select: community
      )
    )
  end

  @doc """
  Get all the community accounts for a specific account (author or user).

  ## Examples

      iex> list_community_accounts_by_account_id(1)
      {:ok, [%CommunityAccount{}, ...]}

      iex> list_community_accounts_by_account_id(123)
      {:ok, []}
  """
  def list_community_accounts_by_account_id(account_id) do
    CommunityAccount
    |> where(author_id: ^account_id)
    |> or_where(user_id: ^account_id)
    |> Repo.all()
  end
end
