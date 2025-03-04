const LoopToggler = {
  mounted() {
    // Store references to important elements
    this.loopList = document.getElementById("loop-list");
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

    // Determine if this is the facilitator view or participant view
    this.isFacilitator = !!document.getElementById("resizable-sidebar");
    this.isParticipant = !!document.getElementById("loops-list");
  },

  toggleLoop(loopId) {
    // If the loop is already selected, unselect it
    if (this.selectedLoopId === loopId) {
      return this.unselectLoop();
    }

    // Update the selected loop
    this.selectedLoopId = loopId;

    // If we have a plot-loops element, update its data-selected-loop attribute
    if (this.plotLoopsEl) {
      this.plotLoopsEl.dataset.selectedLoop = loopId;

      // Trigger an update in the PlotLoops hook
      const event = new CustomEvent("loop-selected", {
        detail: { loopId: loopId },
        bubbles: true,
      });
      this.plotLoopsEl.dispatchEvent(event);
    }

    // Handle facilitator view
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
    }

    if (this.isParticipant) {
      const loopsList = document.getElementById("loops-list");
      const loopHeader = document.getElementById("loop-header");

      if (loopsList) {
        // Hide all loop buttons
        const allLoopButtons = loopsList.querySelectorAll(
          "button[data-loop-id]",
        );
        allLoopButtons.forEach((button) => button.classList.add("hidden"));

        // Hide the header
        if (loopHeader) {
          loopHeader.classList.add("hidden");
        }

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

    // If we have a plot-loops element, update its data attribute
    if (this.plotLoopsEl) {
      delete this.plotLoopsEl.dataset.selectedLoop;

      // Trigger an update in the PlotLoops hook
      const event = new CustomEvent("loop-selected", {
        detail: { loopId: null },
        bubbles: true,
      });
      this.plotLoopsEl.dispatchEvent(event);
    }

    // Handle facilitator view
    if (this.isFacilitator) {
      // Hide all facilitator loop details
      const allFacilitatorDetails = document.querySelectorAll(
        '[id^="loop-detail-facilitator-"]',
      );
      allFacilitatorDetails.forEach((detail) => detail.classList.add("hidden"));
    }

    // Handle participant view
    if (this.isParticipant) {
      const loopsList = document.getElementById("loops-list");
      const loopHeader = document.getElementById("loop-header");

      if (loopsList) {
        // Show all loop buttons
        const allLoopButtons = loopsList.querySelectorAll(
          "button[data-loop-id]",
        );
        allLoopButtons.forEach((button) => button.classList.remove("hidden"));

        // Show the header
        if (loopHeader) {
          loopHeader.classList.remove("hidden");
        }

        // Hide all loop details
        const allDetails = document.querySelectorAll('[id^="loop-detail-"]');
        allDetails.forEach((detail) => detail.classList.add("hidden"));

        // Hide the back button
        if (this.backButton) {
          this.backButton.classList.add("hidden");
        }
      }
    }
  },
};

export default LoopToggler;
