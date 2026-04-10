/**
 * EditorFormSync Hook
 *
 * Syncs ExEditor textarea content with a hidden form input field.
 * Ensures the hidden input always has the current editor value before form submission.
 */
export default {
  mounted() {
    const fieldId = this.el.dataset.fieldId;
    const hiddenInput = this.el;

    if (!fieldId) {
      console.warn("[EditorFormSync] Missing data-field-id attribute");
      return;
    }

    // Store initial hidden input value (from database)
    const initialValue = hiddenInput.value;
    console.log("[EditorFormSync] Initial hidden input value:", initialValue);

    // Find the editor component and textarea
    const findEditor = () => {
      return document.querySelector(`[phx-hook="EditorHook"]`);
    };

    const findTextarea = () => {
      const container = findEditor();
      return container ? container.querySelector('.ex-editor-textarea') : null;
    };

    // Sync textarea value to hidden input
    const syncToHidden = () => {
      const textarea = findTextarea();
      if (textarea && textarea.value) {
        console.log("[EditorFormSync] Syncing textarea to hidden input:", textarea.value.substring(0, 50));
        hiddenInput.value = textarea.value;
      }
    };

    // Sync from hidden input to textarea
    const syncToTextarea = () => {
      const textarea = findTextarea();
      if (textarea && initialValue && !textarea.value) {
        console.log("[EditorFormSync] Syncing hidden input to textarea:", initialValue.substring(0, 50));
        textarea.value = initialValue;
        // Restore the initial value to hidden input as well
        hiddenInput.value = initialValue;
      }
    };

    // Wait for editor to be ready
    let attempts = 0;
    const waitForEditor = setInterval(() => {
      const textarea = findTextarea();
      if (textarea) {
        clearInterval(waitForEditor);
        console.log("[EditorFormSync] Editor found, initializing sync");

        // First, sync from hidden input to textarea if textarea is empty
        syncToTextarea();

        // Then set up event listeners for ongoing sync
        textarea.addEventListener("input", syncToHidden);
        textarea.addEventListener("blur", syncToHidden);
        textarea.addEventListener("change", syncToHidden);

        // Also sync before form submission
        const form = hiddenInput.closest("form");
        if (form) {
          form.addEventListener("submit", syncToHidden);
        }

        // Ensure value is synced before any LiveView event
        document.addEventListener("phx:before-push", syncToHidden);

        console.log("[EditorFormSync] Sync initialized");
      } else if (attempts++ > 30) {
        // Timeout after 30 attempts (3 seconds)
        clearInterval(waitForEditor);
        console.warn("[EditorFormSync] Timeout waiting for editor");

        // Fallback: ensure hidden input keeps its initial value
        hiddenInput.value = initialValue;
      }
    }, 100);
  },
};
