defmodule OliWeb.Common.DeleteModalComponent do
  use Phoenix.LiveComponent
  use Phoenix.HTML

  def render(assigns) do
    ~H"""
    <div class="modal fade show" id={@id} style="display: block" tabindex="-1" role="dialog" aria-labelledby="delete-modal" aria-hidden="true" phx-hook="ModalLaunch">
      <div class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Are you absolutely sure?</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <div class="container form-container">
              <div class="mb-3"><%= @description %></div>
              <div>
                <p>Please type <strong><%= @entity_name %></strong> below to confirm.</p>
              </div>
              <.form
                let={f}
                for={String.to_atom(@entity_type)}
                phx-change="validate_name"
                phx-submit="delete">
                <div class="mt-2">
                  <%= text_input f, :name, class: "form-control", required: true %>
                </div>
                <div class="d-flex">
                  <%= submit "Delete this #{@entity_type}", class: "btn btn-outline-danger mt-2 flex-fill", onclick: "$('##{@id}').modal('hide')", disabled: !@delete_enabled %>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
