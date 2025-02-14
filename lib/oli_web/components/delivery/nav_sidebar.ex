defmodule OliWeb.Components.Delivery.NavSidebar do
  use Phoenix.Component

  import OliWeb.Components.Delivery.Utils
  import Oli.Utils, only: [value_or: 2]
  import Oli.Branding

  alias Oli.Authoring.Course.Project
  alias Oli.Delivery.Hierarchy.HierarchyNode
  alias Oli.Resources.ResourceType
  alias Oli.Resources.Revision
  alias Oli.Publishing.AuthoringResolver
  alias OliWeb.Router.Helpers, as: Routes
  alias Oli.Branding.Brand
  alias OliWeb.Components.Delivery.UserAccountMenu
  alias Oli.Delivery.Sections
  alias Oli.Delivery.Sections.Section
  alias OliWeb.Common.SessionContext

  slot(:inner_block, required: true)

  def main_with_nav(assigns) do
    ~H"""
    <main role="main" class="flex-1 flex flex-col relative lg:flex-row">
      <.navbar {assigns} path_info={@conn.path_info} />

      <div class="flex-1 flex flex-col lg:pl-[200px]">
        <%= render_slot(@inner_block) %>
      </div>
    </main>
    """
  end

  attr(:context, SessionContext)
  attr(:path_info, :list)

  def navbar(assigns) do
    assigns =
      assigns
      |> assign(
        :logo,
        logo_details(assigns)
      )
      |> assign(
        :links,
        if is_preview_mode?(assigns) do
          get_preview_links(assigns)
        else
          get_links(assigns, assigns.path_info)
        end
      )
      |> UserAccountMenu.user_account_menu_assigns()

    ~H"""
    <div id="navbar" phx-update="ignore">
      <%= ReactPhoenix.ClientSide.react_component("Components.Navbar", %{
        logo: @logo,
        links: @links,
        user: @user,
        preview: @preview,
        routes: @routes,
        sectionSlug: @section_slug,
        selectedTimezone: @selected_timezone,
        timezones: @timezones
      }) %>
    </div>
    """
  end

  defp get_preview_links(%{section: %Section{} = section} = assigns) do
    hierarchy =
      section
      |> Oli.Repo.preload([:root_section_resource])
      |> Sections.build_hierarchy()

    [
      %{
        name: "Home",
        href: home_url(assigns),
        active: is_active(assigns.path_info, :overview)
      },
      %{
        name: "Course Content",
        popout: %{
          component: "Components.CourseContentOutline",
          props: %{hierarchy: hierarchy, sectionSlug: section.slug, isPreview: true}
        },
        active: is_active(assigns.path_info, :content)
      },
      %{
        name: "Discussion",
        href: discussion_url(assigns),
        active: is_active(assigns.path_info, :discussion)
      },
      %{
        name: "Assignments",
        href: assignments_url(assigns),
        active: is_active(assigns.path_info, :assignments)
      }
    ]
    |> then(fn links ->
      case section do
        %Section{contains_explorations: true} ->
          links ++
            [
              %{
                name: "Exploration",
                href: exploration_url(assigns),
                active: is_active(assigns.path_info, :exploration)
              }
            ]

        _ ->
          links
      end
    end)
    |> then(fn links ->
      case section do
        %Section{contains_deliberate_practice: true} ->
          links ++
            [
              %{
                name: "Practice",
                href: deliberate_practice_url(assigns),
                active: is_active(assigns.path_info, :deliberate_practice)
              }
            ]

        _ ->
          links
      end
    end)
  end

  defp get_preview_links(%{project: %Project{} = project}) do
    hierarchy =
      AuthoringResolver.full_hierarchy(project.slug)
      |> translate_to_outline()

    [
      %{
        name: "Home",
        href: "#",
        active: false
      },
      %{
        name: "Course Content",
        popout: %{
          component: "Components.CourseContentOutline",
          props: %{
            hierarchy: hierarchy,
            sectionSlug: nil,
            projectSlug: project.slug,
            isPreview: true
          }
        },
        active: true
      },
      %{name: "Discussion", href: "#", active: false},
      %{name: "Assignments", href: "#", active: false}
    ]
  end

  defp get_links(assigns, path_info) do
    hierarchy =
      assigns[:section]
      |> Oli.Repo.preload([:root_section_resource])
      |> Sections.build_hierarchy()

    all = [
      %{
        name: "Home",
        href: home_url(assigns),
        active: is_active(path_info, :overview)
      },
      %{
        name: "Course Content",
        popout: %{
          component: "Components.CourseContentOutline",
          props: %{hierarchy: hierarchy, sectionSlug: assigns[:section].slug}
        },
        active: is_active(path_info, :content)
      },
      %{
        name: "Discussion",
        href: discussion_url(assigns),
        active: is_active(path_info, :discussion)
      },
      %{
        name: "Assignments",
        href: assignments_url(assigns),
        active: is_active(path_info, :assignments)
      }
    ]

    all =
      if assigns.section.contains_explorations do
        all ++
          [
            %{
              name: "Exploration",
              href: exploration_url(assigns),
              active: is_active(path_info, :exploration)
            }
          ]
      else
        all
      end

    if assigns.section.contains_deliberate_practice do
      all ++
        [
          %{
            name: "Practice",
            href: deliberate_practice_url(assigns),
            active: is_active(path_info, :deliberate_practice)
          }
        ]
    else
      all
    end
  end

  defp logo_details(assigns) do
    %{
      href:
        case assigns[:logo_link] do
          nil ->
            logo_link_path(assigns)

          logo_link ->
            logo_link
        end,
      src:
        case assigns do
          %{brand: %Brand{logo: logo, logo_dark: logo_dark}} ->
            %{light: logo, dark: value_or(logo_dark, logo)}

          _ ->
            %{
              light: brand_logo_url(assigns[:section]),
              dark: brand_logo_url_dark(assigns[:section])
            }
        end
    }
  end

  defp is_active(["sections", _, "page", _], :content), do: true
  defp is_active(["sections", _, "container", _], :content), do: true
  defp is_active(["sections", _, "preview", "page", _], :content), do: true
  defp is_active(["sections", _, "preview", "container", _], :content), do: true

  defp is_active(path_info, path) do
    case {List.last(path_info), path} do
      {"overview", :overview} -> true
      {"exploration", :exploration} -> true
      {"discussion", :discussion} -> true
      {"practice", :deliberate_practice} -> true
      {"my_assignments", :assignments} -> true
      _ -> false
    end
  end

  defp home_url(assigns) do
    if assigns[:preview_mode] do
      Routes.page_delivery_path(OliWeb.Endpoint, :index_preview, assigns[:section_slug])
    else
      Routes.page_delivery_path(OliWeb.Endpoint, :index, assigns[:section_slug])
    end
  end

  defp exploration_url(assigns) do
    if assigns[:preview_mode] do
      Routes.page_delivery_path(OliWeb.Endpoint, :exploration_preview, assigns[:section_slug])
    else
      Routes.page_delivery_path(OliWeb.Endpoint, :exploration, assigns[:section_slug])
    end
  end

  defp deliberate_practice_url(assigns) do
    if assigns[:preview_mode] do
      Routes.page_delivery_path(
        OliWeb.Endpoint,
        :deliberate_practice_preview,
        assigns[:section_slug]
      )
    else
      Routes.page_delivery_path(OliWeb.Endpoint, :deliberate_practice, assigns[:section_slug])
    end
  end

  defp discussion_url(assigns) do
    if assigns[:preview_mode] do
      Routes.page_delivery_path(OliWeb.Endpoint, :discussion_preview, assigns[:section_slug])
    else
      Routes.page_delivery_path(OliWeb.Endpoint, :discussion, assigns[:section_slug])
    end
  end

  defp assignments_url(assigns) do
    if assigns[:preview_mode] do
      Routes.page_delivery_path(OliWeb.Endpoint, :assignments_preview, assigns[:section_slug])
    else
      Routes.page_delivery_path(OliWeb.Endpoint, :assignments, assigns[:section_slug])
    end
  end

  defp translate_to_outline(%HierarchyNode{} = node) do
    container_id = ResourceType.get_id_by_type("container")

    case node do
      %{
        uuid: id,
        children: children,
        revision: %Revision{
          resource_type_id: ^container_id,
          title: title,
          slug: slug
        }
      } ->
        # container
        %{
          type: "container",
          children: Enum.map(children, fn c -> translate_to_outline(c) end),
          title: title,
          id: id,
          slug: slug
        }

      %{
        uuid: id,
        revision: %Revision{
          title: title,
          slug: slug
        }
      } ->
        # page
        %{
          type: "page",
          title: title,
          id: id,
          slug: slug
        }
    end
  end
end
