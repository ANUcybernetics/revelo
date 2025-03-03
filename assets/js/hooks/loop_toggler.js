const LoopToggler = {
  mounted() {
    // Store references to important elements
    this.loopList = document.getElementById("loop-list");
    this.loopContent = document.getElementById("loop-content");
    this.backButton = document.getElementById("back-button");

    // Keep track of currently selected loop
    this.selectedLoopId = null;

    // Find the plot loops element
    this.plotLoopsEl = document.getElementById("plot-loops");

    // Register event handlers
    window.addEventListener("toggle-loop", (e) =>
      this.toggleLoop(e.detail.loop_id),
    );
    window.addEventListener("unselect-loop", () => this.unselectLoop());

    // Initial check for facilitator view
    this.isFacilitator = !!document.getElementById("resizable-sidebar");
  },

  toggleLoop(loopId) {
    // If the loop is already selected, unselect it
    if (this.selectedLoopId === loopId) {
      return this.unselectLoop();
    }

    // Update the selected loop
    this.selectedLoopId = loopId;

    // If we have a facilitator view, update the plot-loops data-selected-loop attribute
    if (this.isFacilitator && this.plotLoopsEl) {
      this.plotLoopsEl.dataset.selectedLoop = loopId;

      // Trigger an update in the PlotLoops hook
      const event = new CustomEvent("loop-selected", {
        detail: { loopId: loopId },
        bubbles: true,
      });
      this.plotLoopsEl.dispatchEvent(event);
    }

    if (this.isFacilitator) {
      // For facilitator view, show the loop detail in the sidebar
      const allDetails = document.querySelectorAll(
        '[id^="loop-detail-facilitator-"]',
      );
      allDetails.forEach((detail) => detail.classList.add("hidden"));

      const detailToShow = document.getElementById(
        `loop-detail-facilitator-${loopId}`,
      );
      if (detailToShow) {
        detailToShow.classList.remove("hidden");
      }
    } else {
      // For participant view, switch from list to detail view
      if (this.loopList && this.loopContent) {
        // Hide the loop list and show the loop content container
        this.loopList.classList.add("hidden");
        this.loopContent.classList.remove("hidden");

        // Hide all loop details first
        const allDetails = document.querySelectorAll('[id^="loop-detail-"]');
        allDetails.forEach((detail) => detail.classList.add("hidden"));

        // Show the specific loop detail
        const detailToShow = document.getElementById(`loop-detail-${loopId}`);
        if (detailToShow) {
          detailToShow.classList.remove("hidden");
        }

        // Show the back button
        if (this.backButton) {
          this.backButton.classList.remove("hidden");
        }
      }
    }
  },

  unselectLoop() {
    // Clear the selected loop
    this.selectedLoopId = null;

    // If we have a facilitator view, update the plot-loops data attribute
    if (this.isFacilitator && this.plotLoopsEl) {
      delete this.plotLoopsEl.dataset.selectedLoop;

      // Trigger an update in the PlotLoops hook
      const event = new CustomEvent("loop-selected", {
        detail: { loopId: null },
        bubbles: true,
      });
      this.plotLoopsEl.dispatchEvent(event);

      // Hide all facilitator loop details
      const allFacilitatorDetails = document.querySelectorAll(
        '[id^="loop-detail-facilitator-"]',
      );
      allFacilitatorDetails.forEach((detail) => detail.classList.add("hidden"));
    }

    // Only relevant for participant view
    if (!this.isFacilitator && this.loopList && this.loopContent) {
      // Show the loop list and hide the loop content
      this.loopList.classList.remove("hidden");
      this.loopContent.classList.add("hidden");

      // Hide the back button
      if (this.backButton) {
        this.backButton.classList.add("hidden");
      }
    }
  },
};

export default LoopToggler;
