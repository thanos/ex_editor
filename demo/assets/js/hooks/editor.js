/**
 * ExEditor JavaScript Hook
 *
 * Responsibilities:
 *   - Sync scroll position between textarea and highlight layer
 *   - Update line numbers in the gutter immediately on input (no server round-trip)
 *   - Send debounced content changes to server for syntax highlighting
 *   - Handle Tab key
 *
 * The textarea and gutter are both phx-update="ignore" — LiveView never patches
 * them after mount. Only the highlighted <pre> is updated by the server.
 */
export default {
  mounted() {
    this.textarea = this.el.querySelector(".ex-editor-textarea");
    this.highlight = this.el.querySelector(".ex-editor-highlight");
    this.gutter = this.el.querySelector(".ex-editor-gutter");

    if (!this.textarea || !this.highlight) {
      console.error("[ExEditor] Missing textarea or highlight element");
      return;
    }

    this.debounceTimeout = null;
    this.lastLineCount = 0;

    this.textarea.addEventListener("input", this.onInput.bind(this));
    this.textarea.addEventListener("scroll", this.onScroll.bind(this));
    this.textarea.addEventListener("keydown", this.onKeyDown.bind(this));

    // Initial sync
    this.updateLineNumbers();
    this.syncScroll();
  },

  // Called by LiveView after every DOM patch (highlight layer updated by server)
  updated() {
    // Server has sent fresh highlighting — fade it back in
    this.showHighlightMode();
    this.syncScroll();
  },

  destroyed() {
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
  },

  // --- Event handlers ---

  onInput() {
    this.updateLineNumbers();
    this.syncScroll();
    this.scheduleSync();
    // Show plain textarea text immediately while waiting for server highlight
    this.showTypingMode();
  },

  onScroll() {
    this.syncScroll();
  },

  onKeyDown(e) {
    if (e.key === "Tab") {
      e.preventDefault();
      const start = this.textarea.selectionStart;
      const end = this.textarea.selectionEnd;
      const value = this.textarea.value;
      this.textarea.value =
        value.substring(0, start) + "  " + value.substring(end);
      this.textarea.selectionStart = this.textarea.selectionEnd = start + 2;
      this.updateLineNumbers();
      this.scheduleSync();
    }
  },

  // --- Line numbers ---

  updateLineNumbers() {
    if (!this.gutter) return;
    const lines = this.textarea.value.split("\n").length;
    if (lines === this.lastLineCount) return;
    this.lastLineCount = lines;

    let html = "";
    for (let i = 1; i <= lines; i++) {
      html += `<div class="ex-editor-line-number">${i}</div>`;
    }
    this.gutter.innerHTML = html;
  },

  // --- Typing mode: show plain text instantly, restore highlight on server update ---

  showTypingMode() {
    // Reveal raw textarea text so typing feels instant
    this.textarea.style.webkitTextFillColor = "#d4d4d4";
    // Hide stale highlight (inline style beats any CSS specificity)
    this.highlight.style.opacity = "0";
    this.highlight.style.transition = "none";
  },

  showHighlightMode() {
    // Fade highlight back in with fresh syntax colouring
    this.highlight.style.transition = "opacity 0.7s ease-in";
    this.highlight.style.opacity = "1";
    // Hide raw textarea text again once highlight is ready
    this.textarea.style.webkitTextFillColor = "transparent";
  },

  // --- Scroll sync ---

  syncScroll() {
    const top = this.textarea.scrollTop;
    const left = this.textarea.scrollLeft;
    this.highlight.scrollTop = top;
    this.highlight.scrollLeft = left;
    if (this.gutter) this.gutter.scrollTop = top;
  },

  // --- Content sync to server (debounced, for syntax highlighting only) ---

  scheduleSync() {
    const delay = parseInt(this.el.dataset.debounce) || 300;
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
    this.debounceTimeout = setTimeout(() => {
      this.pushEventTo(this.el, "change", { content: this.textarea.value });
    }, delay);
  },
};
