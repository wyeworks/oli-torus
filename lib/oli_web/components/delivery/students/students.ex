defmodule OliWeb.Components.Delivery.Students do
  use OliWeb, :live_component

  alias Phoenix.LiveView.JS

  alias OliWeb.Common.{PagedTable, SearchInput, Params, Utils}
  alias OliWeb.Delivery.Sections.EnrollmentsTableModel
  alias OliWeb.Router.Helpers, as: Routes

  @default_params %{
    offset: 0,
    limit: 20,
    container_id: nil,
    section_slug: nil,
    page_id: nil,
    sort_order: :asc,
    sort_by: :name,
    text_search: nil,
    filter_by: :enrolled,
    payment_status: nil
  }

  def update(
        %{
          params: params,
          section: section,
          ctx: ctx,
          students: students,
          dropdown_options: dropdown_options
        } = assigns,
        socket
      ) do
    {total_count, rows} = apply_filters(students, params)

    {:ok, table_model} = EnrollmentsTableModel.new(rows, section, ctx)

    table_model =
      Map.merge(table_model, %{
        rows: rows,
        sort_order: params.sort_order,
        sort_by_spec:
          Enum.find(table_model.column_specs, fn col_spec -> col_spec.name == params.sort_by end)
      })

    {:ok,
     assign(socket,
       id: assigns.id,
       total_count: total_count,
       table_model: table_model,
       params: params,
       section_slug: section.slug,
       section_open_and_free: section.open_and_free,
       dropdown_options: dropdown_options,
       view: assigns[:view],
       title: Map.get(assigns, :title, "Students"),
       tab_name: Map.get(assigns, :tab_name, :students),
       show_progress_csv_download: Map.get(assigns, :show_progress_csv_download, false),
       add_enrollments_step: :step_1,
       add_enrollments_selected_role: :student,
       add_enrollments_emails: [],
       add_enrollments_users_not_found: []
     )}
  end

  defp apply_filters(students, params) do
    students =
      students
      |> maybe_filter_by_text(params.text_search)
      |> maybe_filter_by_option(params.filter_by)
      |> sort_by(params.sort_by, params.sort_order)

    {length(students), students |> Enum.drop(params.offset) |> Enum.take(params.limit)}
  end

  defp maybe_filter_by_text(students, nil), do: students
  defp maybe_filter_by_text(students, ""), do: students

  defp maybe_filter_by_text(students, text_search) do
    Enum.filter(students, fn student ->
      String.contains?(
        String.downcase(Utils.name(student.name, student.given_name, student.family_name)),
        String.downcase(text_search)
      )
    end)
  end

  defp maybe_filter_by_option(students, dropdown_value) do
    case dropdown_value do
      :enrolled ->
        Enum.filter(students, fn student ->
          student.enrollment_status == :enrolled and
            student.user_role_id == 4
        end)

      :suspended ->
        Enum.filter(students, fn student ->
          student.enrollment_status == :suspended and
            student.user_role_id == 4
        end)

      :paid ->
        Enum.filter(students, fn student ->
          student.enrollment_status == :enrolled and
            student.user_role_id == 4 and student.payment_status == :paid
        end)

      :not_paid ->
        Enum.filter(students, fn student ->
          student.enrollment_status == :enrolled and
            student.user_role_id == 4 and student.payment_status == :not_paid
        end)

      :grace_period ->
        Enum.filter(students, fn student ->
          student.enrollment_status == :enrolled and
            student.user_role_id == 4 and student.payment_status == :within_grace_period
        end)

      :non_students ->
        Enum.filter(students, fn student ->
          student.enrollment_status == :enrolled and
            student.user_role_id != 4
        end)

      _ ->
        students
    end
  end

  defp sort_by(students, sort_by, sort_order) do
    case sort_by do
      :name ->
        Enum.sort_by(
          students,
          fn student -> Utils.name(student.name, student.given_name, student.family_name) end,
          sort_order
        )

      :email ->
        Enum.sort_by(students, fn student -> student.email end, sort_order)

      :last_interaction ->
        Enum.sort_by(students, fn student -> student.last_interaction end, sort_order)

      :progress ->
        Enum.sort_by(
          students,
          fn student -> {student.progress || 0, student.family_name} end,
          sort_order
        )

      :overall_proficiency ->
        Enum.sort_by(students, fn student -> student.overall_proficiency end, sort_order)

      :engagement ->
        Enum.sort_by(students, fn student -> student.engagement end, sort_order)

      :payment_status ->
        Enum.sort_by(students, fn student -> student.payment_status end, sort_order)

      _ ->
        Enum.sort_by(
          students,
          fn student -> Utils.name(student.name, student.given_name, student.family_name) end,
          sort_order
        )
    end
  end

  attr(:ctx, :map, required: true)
  attr(:title, :string, default: "Students")
  attr(:tab_name, :atom, default: :students)
  attr(:section_slug, :string, default: nil)
  attr(:section_open_and_free, :boolean, default: false)
  attr(:params, :map, required: true)
  attr(:total_count, :integer, required: true)
  attr(:table_model, :map, required: true)
  attr(:dropdown_options, :list, required: true)
  attr(:show_progress_csv_download, :boolean, default: false)
  attr(:view, :atom)
  attr(:add_enrollments_step, :atom, default: :step_1)
  attr(:add_enrollments_selected_role, :atom, default: :student)
  attr(:add_enrollments_emails, :list, default: [])
  attr(:add_enrollments_users_not_found, :list, default: [])

  def render(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col gap-2 mx-10 mb-10">
      <.live_component
        module={OliWeb.Components.LiveModal}
        id="students_table_add_enrollments_modal"
        title="Add enrollments"
        on_confirm={
          case @add_enrollments_step do
            :step_1 -> JS.push("add_enrollments_go_to_step_2", target: @myself)
            :step_2 -> JS.push("add_enrollments_go_to_step_3", target: @myself)
            :step_3 -> JS.dispatch("click", to: "#add_enrollments_form button")
          end
        }
        on_confirm_label={if @add_enrollments_step == :step_3, do: "Confirm", else: "Next"}
        on_cancel={
          if @add_enrollments_step == :step_1,
            do: nil,
            else: JS.push("add_enrollments_go_to_step_1", target: @myself)
        }
        on_confirm_disabled={if length(@add_enrollments_emails) == 0, do: true, else: false}
        on_cancel_label={if @add_enrollments_step == :step_1, do: nil, else: "Back"}
      >
        <.add_enrollments
          add_enrollments_emails={@add_enrollments_emails}
          add_enrollments_step={@add_enrollments_step}
          add_enrollments_selected_role={@add_enrollments_selected_role}
          add_enrollments_users_not_found={@add_enrollments_users_not_found}
          section_slug={@section_slug}
          target={@id}
        />
      </.live_component>
      <div class="bg-white dark:bg-gray-800 shadow-sm">
        <div class="flex justify-between sm:items-end px-4 sm:px-9 py-4 instructor_dashboard_table">
          <div>
            <h4 class="torus-h4 !py-0 sm:mr-auto mb-2"><%= @title %></h4>
            <%= if @show_progress_csv_download do %>
              <a
                class="self-end"
                href={
                  Routes.metrics_path(
                    OliWeb.Endpoint,
                    :download_container_progress,
                    @section_slug,
                    @params.container_id
                  )
                }
                download="progress.csv"
              >
                <i class="fa-solid fa-download mr-1" /> Download student progress CSV
              </a>
            <% else %>
              <a
                href={
                  Routes.delivery_path(OliWeb.Endpoint, :download_students_progress, @section_slug)
                }
                class="self-end"
              >
                <i class="fa-solid fa-download ml-1" /> Download
              </a>
            <% end %>
          </div>
          <div class="flex flex-col-reverse sm:flex-row gap-2 items-end">
            <button
              :if={@section_open_and_free}
              phx-click="open"
              phx-target="#students_table_add_enrollments_modal"
              class="torus-button primary mr-4"
            >
              Add Enrollments
            </button>
            <div class="flex w-full sm:w-auto sm:items-end gap-2">
              <form class="w-full" phx-change="filter_by" phx-target={@myself}>
                <label class="cursor-pointer inline-flex flex-col gap-1 w-full">
                  <small class="torus-small uppercase">Filter by</small>
                  <select class="torus-select" name="filter">
                    <option
                      :for={elem <- @dropdown_options}
                      selected={@params.filter_by == elem.value}
                      value={elem.value}
                    >
                      <%= elem.label %>
                    </option>
                  </select>
                </label>
              </form>
            </div>
            <form for="search" phx-target={@myself} phx-change="search_student" class="w-44">
              <SearchInput.render
                id="students_search_input"
                name="student_name"
                text={@params.text_search}
              />
            </form>
          </div>
        </div>

        <PagedTable.render
          table_model={@table_model}
          total_count={@total_count}
          offset={@params.offset}
          limit={@params.limit}
          render_top_info={false}
          additional_table_class="instructor_dashboard_table"
          sort={JS.push("paged_table_sort", target: @myself)}
          page_change={JS.push("paged_table_page_change", target: @myself)}
          limit_change={JS.push("paged_table_limit_change", target: @myself)}
          show_limit_change={true}
        />
      </div>
    </div>
    """
  end

  #### Add enrollments modal related stuff ####
  def add_enrollments(%{add_enrollments_step: :step_1} = assigns) do
    ~H"""
    <div class="px-4">
      <p class="mb-2">
        Please write the email addresses of the users you want to invite to the course.
      </p>
      <OliWeb.Components.EmailList.render
        id="enrollments_email_list"
        users_list={@add_enrollments_emails}
        on_update="add_enrollments_update_list"
        on_remove="add_enrollments_remove_from_list"
        target={@target}
      />
      <label class="flex flex-col mt-4 w-40 ml-auto">
        <small class="torus-small uppercase">Role</small>
        <form class="w-full" phx-change="add_enrollments_change_selected_role">
          <select name="role" class="torus-select w-full">
            <option selected={:instructor == @add_enrollments_selected_role} value={:instructor}>
              Instructor
            </option>
            <option selected={:student == @add_enrollments_selected_role} value={:student}>
              Student
            </option>
          </select>
        </form>
      </label>
    </div>
    """
  end

  def add_enrollments(%{add_enrollments_step: :step_2} = assigns) do
    ~H"""
    <div class="px-4">
      <p>
        The following emails don't exist in the database. If you still want to proceed, an email will be sent and they
        will become enrolled once they sign up. Please, review them and click on "Next" to continue.
      </p>
      <div>
        <li class="list-none mt-4 max-h-80 overflow-y-scroll">
          <%= for user <- @add_enrollments_users_not_found do %>
            <ul class="odd:bg-gray-200 dark:odd:bg-neutral-600 even:bg-gray-100 dark:even:bg-neutral-500 p-2 first:rounded-t last:rounded-b">
              <div class="flex items-center justify-between">
                <p><%= user %></p>
                <button
                  phx-click={
                    JS.push("add_enrollments_remove_from_list",
                      value: %{user: user},
                      target: "##{@target}"
                    )
                  }
                  class="torus-button error"
                >
                  Remove
                </button>
              </div>
            </ul>
          <% end %>
        </li>
      </div>
    </div>
    """
  end

  def add_enrollments(%{add_enrollments_step: :step_3} = assigns) do
    ~H"""
    <.form
      for={%{}}
      id="add_enrollments_form"
      class="hidden"
      method="POST"
      action={Routes.invite_path(OliWeb.Endpoint, :create_bulk, @section_slug)}
    >
      <%= for email <- @add_enrollments_emails do %>
        <input name="emails[]" value={email} hidden />
      <% end %>
      <input name="role" value={@add_enrollments_selected_role} />
      <input name="section_slug" value={@section_slug} />
      <button type="submit" class="hidden" />
    </.form>
    <div class="px-4">
      <p>
        Are you sure you want to enroll <%= "#{if length(@add_enrollments_emails) == 1, do: "one user", else: "#{length(@add_enrollments_emails)} users"}" %>?
      </p>
    </div>
    """
  end

  def handle_event("add_enrollments_go_to_step_1", _, socket) do
    {:noreply, assign(socket, :add_enrollments_step, :step_1)}
  end

  def handle_event("add_enrollments_go_to_step_2", _, socket) do
    users = socket.assigns.add_enrollments_emails
    existing_users = Oli.Accounts.get_users_by_email(users) |> Enum.map(& &1.email)
    add_enrollments_users_not_found = users -- existing_users

    case length(add_enrollments_users_not_found) do
      0 ->
        {:noreply,
         assign(socket, %{
           add_enrollments_step: :step_3
         })}

      _ ->
        {:noreply,
         assign(socket, %{
           add_enrollments_step: :step_2,
           add_enrollments_users_not_found: add_enrollments_users_not_found
         })}
    end
  end

  def handle_event("add_enrollments_go_to_step_3", _, socket) do
    {:noreply,
     assign(socket, %{
       add_enrollments_step: :step_3
     })}
  end

  def handle_event("add_enrollments_change_selected_role", %{"role" => role}, socket) do
    {:noreply, assign(socket, :add_enrollments_selected_role, String.to_existing_atom(role))}
  end

  def handle_event("add_enrollments_update_list", %{"value" => list}, socket)
      when is_list(list) do
    add_enrollments_emails = socket.assigns.add_enrollments_emails

    socket =
      if list != [] do
        add_enrollments_emails = Enum.concat(add_enrollments_emails, list) |> Enum.uniq()

        assign(socket, %{
          add_enrollments_emails: add_enrollments_emails
        })
      end

    {:noreply, socket}
  end

  def handle_event("add_enrollments_update_list", %{"value" => value}, socket) do
    add_enrollments_emails = socket.assigns.add_enrollments_emails

    socket =
      if String.length(value) != 0 && !Enum.member?(add_enrollments_emails, value) do
        add_enrollments_emails = add_enrollments_emails ++ [String.downcase(value)]

        assign(socket, %{
          add_enrollments_emails: add_enrollments_emails
        })
      end

    {:noreply, socket}
  end

  def handle_event("add_enrollments_remove_from_list", %{"user" => user}, socket) do
    add_enrollments_emails = Enum.filter(socket.assigns.add_enrollments_emails, &(&1 != user))

    add_enrollments_users_not_found =
      Enum.filter(socket.assigns.add_enrollments_users_not_found, &(&1 != user))

    step =
      cond do
        length(add_enrollments_emails) == 0 ->
          :step_1

        socket.assigns.add_enrollments_step == :step_2 and
            length(add_enrollments_users_not_found) == 0 ->
          :step_1

        true ->
          socket.assigns.add_enrollments_step
      end

    {:noreply,
     assign(socket, %{
       add_enrollments_emails: add_enrollments_emails,
       add_enrollments_users_not_found: add_enrollments_users_not_found,
       add_enrollments_step: step
     })}
  end

  #### End of enrollments modal related stuff ####

  def handle_event("search_student", %{"student_name" => student_name}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           OliWeb.Delivery.InstructorDashboard.InstructorDashboardLive,
           socket.assigns.section_slug,
           socket.assigns.view,
           socket.assigns.tab_name,
           update_params(socket.assigns.params, %{text_search: student_name, offset: 0})
         )
     )}
  end

  def handle_event("paged_table_page_change", %{"limit" => limit, "offset" => offset}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           OliWeb.Delivery.InstructorDashboard.InstructorDashboardLive,
           socket.assigns.section_slug,
           socket.assigns.view,
           socket.assigns.tab_name,
           update_params(socket.assigns.params, %{limit: limit, offset: offset})
         )
     )}
  end

  def handle_event(
        "paged_table_limit_change",
        params,
        %{assigns: %{params: current_params}} = socket
      ) do
    new_limit = Params.get_int_param(params, "limit", 20)

    new_offset =
      OliWeb.Common.PagingParams.calculate_new_offset(
        current_params.offset,
        new_limit,
        socket.assigns.total_count
      )

    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           OliWeb.Delivery.InstructorDashboard.InstructorDashboardLive,
           socket.assigns.section_slug,
           socket.assigns.view,
           socket.assigns.tab_name,
           update_params(socket.assigns.params, %{limit: new_limit, offset: new_offset})
         )
     )}
  end

  def handle_event("paged_table_sort", %{"sort_by" => sort_by} = _params, socket) do
    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           OliWeb.Delivery.InstructorDashboard.InstructorDashboardLive,
           socket.assigns.section_slug,
           socket.assigns.view,
           socket.assigns.tab_name,
           update_params(socket.assigns.params, %{sort_by: String.to_existing_atom(sort_by)})
         )
     )}
  end

  def handle_event("filter_by", %{"filter" => filter}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           OliWeb.Delivery.InstructorDashboard.InstructorDashboardLive,
           socket.assigns.section_slug,
           socket.assigns.view,
           socket.assigns.tab_name,
           update_params(socket.assigns.params, %{filter_by: String.to_existing_atom(filter)})
         )
     )}
  end

  def decode_params(params) do
    %{
      offset: Params.get_int_param(params, "offset", @default_params.offset),
      limit: Params.get_int_param(params, "limit", @default_params.limit),
      container_id: Params.get_int_param(params, "container_id", @default_params.container_id),
      section_slug: Params.get_int_param(params, "section_slug", @default_params.section_slug),
      page_id: Params.get_int_param(params, "page_id", @default_params.page_id),
      sort_order:
        Params.get_atom_param(params, "sort_order", [:asc, :desc], @default_params.sort_order),
      sort_by:
        Params.get_atom_param(
          params,
          "sort_by",
          [
            :name,
            :email,
            :last_interaction,
            :progress,
            :overall_proficiency,
            :engagement,
            :payment_status
          ],
          @default_params.sort_by
        ),
      text_search: Params.get_param(params, "text_search", @default_params.text_search),
      filter_by:
        Params.get_atom_param(
          params,
          "filter_by",
          [:enrolled, :suspended, :paid, :not_paid, :grace_period, :non_students],
          @default_params.filter_by
        )
    }
  end

  defp update_params(%{sort_by: current_sort_by, sort_order: current_sort_order} = params, %{
         sort_by: new_sort_by
       })
       when current_sort_by == new_sort_by do
    toggled_sort_order = if current_sort_order == :asc, do: :desc, else: :asc
    update_params(params, %{sort_order: toggled_sort_order})
  end

  defp update_params(params, new_param) do
    Map.merge(params, new_param)
    |> purge_default_params()
  end

  defp purge_default_params(params) do
    # there is no need to add a param to the url if its value is equal to the default one
    Map.filter(params, fn {key, value} ->
      @default_params[key] != value
    end)
  end
end
