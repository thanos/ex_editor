/**
 * EditorFormSync Hook
 *
 * Syncs ExEditor textarea content with a hidden form input field.
 * Watches for changes to the textarea and updates the corresponding form input.
 */
export default {
  mounted() {
    const fieldId = this.el.dataset.fieldId;
    if (!fieldId) {
      console.warn("[EditorFormSync] Missing data-field-id attribute");
      return;
    }

    // Find the editor component and textarea
    const container = document.querySelector(`[phx-hook="EditorHook"]`);
    if (!container) {
      console.warn("[EditorFormSync] No EditorHook container found");
      return;
    }

    const textarea = container.querySelector('.ex-editor-textarea');
    if (!textarea) {
      console.warn("[EditorFormSync] No textarea found");
      return;
    }

    // Sync textarea value to hidden input on input event
    const syncValue = () => {
      this.el.value = textarea.value;
      // Trigger change event so form validation works
      const event = new Event("change", { bubbles: true });
      this.el.dispatchEvent(event);
    };

    // Sync on every input change
    textarea.addEventListener("input", syncValue);

    // Also sync on blur to ensure final value is captured
    textarea.addEventListener("blur", syncValue);

    // Sync immediately on mount
    syncValue();
  },
};
