/**
 * EditorFormSync Hook
 *
 * Syncs ExEditor content changes with a hidden form input field.
 * Listens for code_changed events from the LiveEditor component
 * and updates the corresponding form input.
 */
export default {
  mounted() {
    const fieldId = this.el.dataset.fieldId;
    if (!fieldId) {
      console.warn("[EditorFormSync] Missing data-field-id attribute");
      return;
    }

    // Store the field ID for use in event listeners
    this.fieldId = fieldId;

    // Listen for code_changed events from the parent LiveView
    this.handleEvent("code_changed", ({ content }) => {
      // Update the hidden input value
      this.el.value = content;

      // Trigger change event so form validation works
      const event = new Event("change", { bubbles: true });
      this.el.dispatchEvent(event);
    });
  },
};
