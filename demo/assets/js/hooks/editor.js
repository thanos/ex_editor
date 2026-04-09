/**
 * ExEditor JavaScript Hook
 *
 * Responsibilities:
 *   - Sync scroll position between textarea and highlight layer
 *   - Update line numbers in the gutter immediately on input (no server round-trip)
 *   - Send incremental diffs to server for real-time syntax highlighting
 *   - Handle Tab key, blur events for content safety
 *
 * The textarea and gutter are both phx-update="ignore" — LiveView never patches
 * them after mount. Only the highlighted <pre> is updated by the server.
 *
 * ## Strategy
 * Typing mode removed: highlight layer always stays visible at opacity 1, lagging
 * by ~50ms (the debounce delay) rather than 2+ seconds. Diffs are sent immediately,
 * reducing payload size and server processing time.
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
    this.prevValue = this.textarea.value; // Baseline for diff computation

    this.textarea.addEventListener("input", this.onInput.bind(this));
    this.textarea.addEventListener("scroll", this.onScroll.bind(this));
    this.textarea.addEventListener("keydown", this.onKeyDown.bind(this));

    // Safety full-sync on blur (corrects any divergence)
    this.textarea.addEventListener("blur", () => {
      if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
      this.prevValue = this.textarea.value;
      this.pushEventTo(this.el, "change", { content: this.textarea.value });
    });

    // Safety full-sync after paste (large selections may not diff cleanly)
    this.textarea.addEventListener("paste", () => {
      setTimeout(() => {
        if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
        this.prevValue = this.textarea.value;
        this.pushEventTo(this.el, "change", { content: this.textarea.value });
      }, 0);
    });

    // Initial sync
    this.updateLineNumbers();
    this.syncScroll();
  },

  // Called by LiveView after every DOM patch (highlight layer updated by server)
  updated() {
    // Highlight layer is always visible; just keep scroll positions in sync
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

  // --- Diff computation ---

  computeDiff(prev, next) {
    // Find longest common prefix
    let from = 0;
    while (
      from < prev.length &&
      from < next.length &&
      prev[from] === next[from]
    ) {
      from++;
    }

    // Find longest common suffix
    let prevEnd = prev.length;
    let nextEnd = next.length;
    while (
      prevEnd > from &&
      nextEnd > from &&
      prev[prevEnd - 1] === next[nextEnd - 1]
    ) {
      prevEnd--;
      nextEnd--;
    }

    return { from, to: prevEnd, text: next.slice(from, nextEnd) };
  },

  // --- Scroll sync ---

  syncScroll() {
    const top = this.textarea.scrollTop;
    const left = this.textarea.scrollLeft;
    this.highlight.scrollTop = top;
    this.highlight.scrollLeft = left;
    if (this.gutter) this.gutter.scrollTop = top;
  },

  // --- Content sync to server: send incremental diffs (fast, small payload) ---

  scheduleSync() {
    const delay = parseInt(this.el.dataset.debounce) || 50;
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
    this.debounceTimeout = setTimeout(() => {
      const current = this.textarea.value;
      const diff = this.computeDiff(this.prevValue, current);
      this.prevValue = current;
      this.pushEventTo(this.el, "diff", diff);
    }, delay);
  },
};
