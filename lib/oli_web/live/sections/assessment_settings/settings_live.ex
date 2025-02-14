defmodule OliWeb.Sections.AssessmentSettings.SettingsLive do
  use Phoenix.LiveView
  use OliWeb.Common.Modal

  import Ecto.Query
  alias Oli.Repo

  alias OliWeb.Sections.Mount
  alias OliWeb.Common.{SessionContext, Breadcrumb}
  alias Oli.Publishing.DeliveryResolver
  alias Oli.Delivery.{Settings, Sections}
  alias OliWeb.Router.Helpers, as: Routes
  alias Oli.Delivery.Settings.StudentException

  @impl true
  def mount(%{"section_slug" => section_slug} = _params, session, socket) do
    case Mount.for(section_slug, session) do
      {:error, error} ->
        {:ok, redirect(socket, to: Routes.static_page_path(OliWeb.Endpoint, error))}

      {_user_type, current_user, section} ->
        section =
          section
          |> Oli.Repo.preload([:base_project, :root_section_resource])

        student_exceptions = get_student_exceptions(section.id)

        {:ok,
         assign(socket,
           ctx: SessionContext.init(socket, session, user: current_user),
           current_user: current_user,
           preview_mode: socket.assigns[:live_action] == :preview,
           title: "Assessment Settings",
           section: section,
           student_exceptions: student_exceptions,
           students:
             Sections.enrolled_students(section.slug)
             |> Enum.reject(fn s -> s.user_role_id != 4 end)
             |> Enum.sort(),
           assessments: get_assessments(section.slug, student_exceptions),
           breadcrumbs: [
             Breadcrumb.new(%{
               full_title: "Manage Section",
               link:
                 Routes.live_path(
                   OliWeb.Endpoint,
                   OliWeb.Delivery.InstructorDashboard.InstructorDashboardLive,
                   section.slug,
                   :manage
                 )
             }),
             Breadcrumb.new(%{
               full_title: "Assessments settings"
             })
           ]
         )}
    end
  end

  @impl Phoenix.LiveView
  def handle_params(%{"active_tab" => "settings"} = params, _, socket) do
    socket =
      socket
      |> assign(
        params: params,
        active_tab: :settings,
        update_sort_order: true
      )

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"active_tab" => "student_exceptions"} = params, _, socket) do
    socket =
      socket
      |> assign(
        params: params,
        active_tab: :student_exceptions,
        update_sort_order: true
      )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto my-4">
      <div class="flex mx-10">
        <ul
          class="nav nav-tabs flex flex-col md:flex-row flex-wrap list-none border-b-0 pl-0 mb-4"
          id="tabs-tab"
          role="tablist"
        >
          <%= for {label, tab_name, active} <- [
              {"Assessment Settings", :settings, is_active_tab?(:settings, @active_tab)},
              {"Student Exceptions", :student_exceptions, is_active_tab?(:student_exceptions, @active_tab)},
            ] do %>
            <li class="nav-item" role="presentation">
              <a
                phx-click="change_tab"
                phx-value-selected_tab={tab_name}
                class={"
                    block
                    border-x-0 border-t-0 border-b-2
                    px-1
                    py-3
                    m-2
                    text-body-color
                    dark:text-body-color-dark
                    bg-transparent
                    hover:no-underline
                    hover:text-body-color
                    hover:border-delivery-primary-200
                    focus:border-delivery-primary-200
                    #{if active, do: "border-delivery-primary", else: "border-transparent"}
                  "}
              >
                <%= label %>
              </a>
            </li>
          <% end %>
        </ul>
        <div class="ml-auto"><.flash_message flash={@flash} /></div>
      </div>
      <%= if @active_tab == :settings do %>
        <.live_component
          id="assessment_settings_table"
          module={OliWeb.Sections.AssessmentSettings.SettingsTable}
          assessments={@assessments}
          params={@params}
          section={@section}
          ctx={@ctx}
          update_sort_order={@update_sort_order}
        />
      <% else %>
        <.live_component
          id="student_exeptions_table"
          module={OliWeb.Sections.AssessmentSettings.StudentExceptionsTable}
          student_exceptions={@student_exceptions}
          students={@students}
          assessments={@assessments}
          params={@params}
          section={@section}
          ctx={@ctx}
        />
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("change_tab", %{"selected_tab" => "student_exceptions"}, socket) do
    first_assessment_id =
      if socket.assigns.assessments == [],
        do: :all,
        else: hd(socket.assigns.assessments).resource_id

    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           __MODULE__,
           socket.assigns.section.slug,
           "student_exceptions",
           first_assessment_id
         )
     )}
  end

  @impl true
  def handle_event("change_tab", %{"selected_tab" => selected_tab}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           __MODULE__,
           socket.assigns.section.slug,
           selected_tab,
           :all
         )
     )}
  end

  @impl true
  def handle_info({:flash_message, type, message}, socket) do
    {:noreply, socket |> clear_flash |> put_flash(type, message)}
  end

  @impl true
  def handle_info({:assessment_updated, updated_assessment, update_sort_order}, socket) do
    updated_assessments =
      socket.assigns.assessments
      |> Enum.into([], fn assessment ->
        if assessment.resource_id == updated_assessment.resource_id,
          do: updated_assessment,
          else: assessment
      end)

    {:noreply,
     socket
     |> assign(
       assessments: updated_assessments,
       update_sort_order: update_sort_order
     )}
  end

  @impl true
  def handle_info({:student_exception, action, student_exceptions, update_sort_order}, socket)
      when is_list(student_exceptions) do
    updated_student_exceptions =
      case action do
        :updated ->
          socket.assigns.student_exceptions
          |> Enum.into([], fn se ->
            Enum.find(student_exceptions, se, fn s_ex -> s_ex.id == se.id end)
          end)

        :added ->
          student_exceptions ++ socket.assigns.student_exceptions

        :deleted ->
          ids = Enum.map(student_exceptions, fn se -> se.id end)

          Enum.reject(socket.assigns.student_exceptions, fn se ->
            se.id in ids
          end)
      end

    updated_assessments =
      socket.assigns.assessments
      |> update_assessments_students_exception_count(updated_student_exceptions)

    {:noreply,
     socket
     |> assign(
       student_exceptions: updated_student_exceptions,
       assessments: updated_assessments,
       update_sort_order: update_sort_order
     )}
  end

  defp update_assessments_students_exception_count(assessments, student_exceptions) do
    exceptions_resource_id = Enum.group_by(student_exceptions, fn se -> se.resource_id end)

    assessments
    |> Enum.map(fn a ->
      exceptions_count = Map.get(exceptions_resource_id, a.resource_id, []) |> length()
      Map.merge(a, %{exceptions_count: exceptions_count})
    end)
  end

  defp is_active_tab?(tab, active_tab), do: tab == active_tab

  defp get_assessments(section_slug, student_exceptions) do
    DeliveryResolver.graded_pages_revisions_and_section_resources(section_slug)
    |> Enum.with_index()
    |> Enum.map(fn {{rev, sr}, index} ->
      Settings.combine(rev, sr, nil)
      |> Map.merge(%{
        index: index + 1,
        name: rev.title,
        scheduling_type: sr.scheduling_type,
        password: sr.password,
        exceptions_count:
          Enum.count(student_exceptions, fn se -> se.resource_id == rev.resource_id end)
      })
    end)
  end

  defp get_student_exceptions(section_id) do
    StudentException
    |> where(section_id: ^section_id)
    |> preload(:user)
    |> Repo.all()
  end

  defp flash_message(assigns) do
    ~H"""
    <%= if live_flash(@flash, :info) do %>
      <div class="alert alert-info flex flex-row justify-between" role="alert">
        <%= live_flash(@flash, :info) %>
        <button
          type="button"
          class="close ml-4"
          data-bs-dismiss="alert"
          aria-label="Close"
          phx-click="lv:clear-flash"
          phx-value-key="info"
        >
          <i class="fa-solid fa-xmark fa-lg" />
        </button>
      </div>
    <% end %>
    <%= if live_flash(@flash, :error) do %>
      <div class="alert alert-danger flex flex-row justify-between" role="alert">
        {live_flash(@flash, :error)}
        <button
          type="button"
          class="close ml-4"
          data-bs-dismiss="alert"
          aria-label="Close"
          phx-click="lv:clear-flash"
          phx-value-key="error"
        >
          <i class="fa-solid fa-xmark fa-lg" />
        </button>
      </div>
    <% end %>
    """
  end
end
