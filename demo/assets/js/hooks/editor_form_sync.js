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
    // The editor is rendered in a preceding sibling container (usually a div.border)
    // This hook is on the hidden input that comes right after that container
    const findEditor = () => {
      // Strategy 1: The editor should be in a direct preceding sibling
      // (the div that wraps the LiveComponent)
      let current = hiddenInput.previousElementSibling;
      while (current) {
        const editor = current.querySelector(`[phx-hook="EditorHook"]`);
        if (editor) {
          console.log("[EditorFormSync] Found editor in previous sibling");
          return editor;
        }
        // Only check immediate preceding siblings, not all ancestors
        current = current.previousElementSibling;
      }

      // Strategy 2: Look in the field container (for nested structures)
      const fieldContainer = hiddenInput.closest("div[class*='field']");
      if (fieldContainer) {
        // Get all editors in this container
        const editorsInContainer = fieldContainer.querySelectorAll(`[phx-hook="EditorHook"]`);

        if (editorsInContainer.length === 1) {
          // Only one editor in this field - it's the right one
          console.log("[EditorFormSync] Found single editor in field container");
          return editorsInContainer[0];
        } else if (editorsInContainer.length > 1) {
          // Multiple editors - find the one that comes before this hidden input
          for (let editor of editorsInContainer) {
            // Check if this editor comes before the hidden input in document order
            if (hiddenInput.compareDocumentPosition(editor) === 4) {
              // DOCUMENT_POSITION_PRECEDING = 4 (editor comes before the input)
              console.log("[EditorFormSync] Found preceding editor in field");
              return editor;
            }
          }
        }
      }

      // Fallback: if only one editor exists on the entire page, use it
      const allEditors = document.querySelectorAll(`[phx-hook="EditorHook"]`);
      if (allEditors.length === 1) {
        console.log("[EditorFormSync] Using single editor (fallback)");
        return allEditors[0];
      }

      return null;
    };

    const findTextarea = () => {
      const container = findEditor();
      if (!container) {
        console.warn("[EditorFormSync] Could not find editor container");
        return null;
      }
      const textarea = container.querySelector('.ex-editor-textarea');
      if (textarea) {
        console.log("[EditorFormSync] Found textarea for field:", fieldId);
      }
      return textarea;
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
