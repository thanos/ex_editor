export default {
  mounted() {
    console.log("EditorSync hook mounted");
    this.handleInput = this.handleInput.bind(this);
    this.handleScroll = this.handleScroll.bind(this);
    this.handleCursorUpdate = this.handleCursorUpdate.bind(this);

    // Attach event listeners
    this.el.addEventListener("input", this.handleInput);
    this.el.addEventListener("scroll", this.handleScroll);
    this.el.addEventListener("select", this.handleCursorUpdate);
    this.el.addEventListener("click", this.handleCursorUpdate);
    this.el.addEventListener("keyup", this.handleCursorUpdate);

    console.log("EditorSync event listeners attached");
  },

  destroyed() {
    console.log("EditorSync hook destroyed");
    this.el.removeEventListener("input", this.handleInput);
    this.el.removeEventListener("scroll", this.handleScroll);
    this.el.removeEventListener("select", this.handleCursorUpdate);
    this.el.removeEventListener("click", this.handleCursorUpdate);
    this.el.removeEventListener("keyup", this.handleCursorUpdate);
  },

  handleInput(event) {
    console.log("EditorSync input event fired");

    // Debounce the input to avoid too many updates
    if (this.inputTimeout) {
      clearTimeout(this.inputTimeout);
    }

    this.inputTimeout = setTimeout(() => {
      console.log("EditorSync pushing content update");
      const content = this.el.value;
      this.pushEvent("update_content", { content });
    }, 300);
  },

  handleScroll(event) {
    console.log("EditorSync scroll event fired");
    // Sync scroll position between textarea and any overlay elements
    const scrollTop = this.el.scrollTop;
    const scrollLeft = this.el.scrollLeft;

    // If there's an overlay element, sync its scroll
    const overlay = document.querySelector(".ex-editor-overlay");
    if (overlay) {
      overlay.scrollTop = scrollTop;
      overlay.scrollLeft = scrollLeft;
    }
  },

  handleCursorUpdate(event) {
    console.log("EditorSync cursor update event fired");
    const selectionStart = this.el.selectionStart;
    const selectionEnd = this.el.selectionEnd;

    console.log("Pushing cursor update:", {
      selection_start: selectionStart,
      selection_end: selectionEnd,
    });

    this.pushEvent("update_cursor", {
      selection_start: selectionStart,
      selection_end: selectionEnd,
    });
  },
};
