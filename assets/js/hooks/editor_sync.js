export default {
  mounted() {
    this.handleInput = this.handleInput.bind(this);
    this.handleScroll = this.handleScroll.bind(this);

    // Debounce to avoid excessive updates
    this.debounceTimer = null;
    this.debounceDelay = 50; // 50ms debounce

    // Listen for input events
    this.el.addEventListener("input", this.handleInput);
    this.el.addEventListener("scroll", this.handleScroll);

    // Initial scroll sync
    this.syncScroll();
  },

  updated() {
    // Sync scroll when LiveView updates
    this.syncScroll();
  },

  handleInput(e) {
    clearTimeout(this.debounceTimer);

    this.debounceTimer = setTimeout(() => {
      // Push the content to the server
      this.pushEvent("update_content", { content: this.el.value });
    }, this.debounceDelay);
  },

  handleScroll(e) {
    this.syncScroll();
  },

  syncScroll() {
    const overlay = this.el.parentElement.querySelector(".pointer-events-none");
    if (overlay) {
      overlay.scrollTop = this.el.scrollTop;
      overlay.scrollLeft = this.el.scrollLeft;
    }
  },

  destroyed() {
    this.el.removeEventListener("input", this.handleInput);
    this.el.removeEventListener("scroll", this.handleScroll);
    clearTimeout(this.debounceTimer);
  },
};
