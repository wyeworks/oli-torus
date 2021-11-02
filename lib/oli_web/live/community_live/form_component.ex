defmodule OliWeb.CommunityLive.FormComponent do
  use Surface.Component

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea, TextInput}

  prop changeset, :changeset
  prop display_labels, :boolean, default: true

  def render(assigns) do
    ~F"""
    <Form for={@changeset} submit="save">
      <Field name={:name} class="form-group">
        {#if @display_labels}
          <Label class="control-label">Community Name</Label>
        {/if}
        <TextInput class="form-control" opts={placeholder: "Name"}/>
        <ErrorTag/>
      </Field>

      <Field name={:description} class="form-group">
        {#if @display_labels}
          <Label class="control-label">Community Description</Label>
        {/if}
        <TextArea class="form-control" rows="4" opts={placeholder: "Description"}/>
      </Field>

      <Field name={:key_contact} class="form-group">
        {#if @display_labels}
          <Label class="control-label">Community Contact</Label>
        {/if}
        <TextInput class="form-control" opts={placeholder: "Key Contact"}/>
      </Field>

      <button class="form-button btn btn-md btn-primary btn-block" type="submit">Save</button>
    </Form>
    """
  end
end
