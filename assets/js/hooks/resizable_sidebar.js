export const ResizableSidebar = {
  mounted() {
    const sidebar = this.el;
    const handle = sidebar.querySelector(".resize-handle");
    const plotContainer = document.getElementById("plot-loops");
    let isResizing = false;
    let initialWidth;
    let initialX;

    // Minimum and maximum widths for the sidebar
    const minWidth = 250;
    const maxWidth = window.innerWidth * 0.8;

    handle.addEventListener("mousedown", (e) => {
      isResizing = true;
      initialWidth = sidebar.offsetWidth;
      initialX = e.clientX;

      // Add a class to indicate resizing is in progress
      document.body.classList.add("sidebar-resizing");
      e.preventDefault();
    });

    document.addEventListener("mousemove", (e) => {
      if (!isResizing) return;

      // Calculate new width (note: moving left decreases width)
      const deltaX = initialX - e.clientX;
      let newWidth = initialWidth + deltaX;

      // Apply constraints
      newWidth = Math.max(minWidth, Math.min(maxWidth, newWidth));

      // Apply the new width
      sidebar.style.width = `${newWidth}px`;

      // Update plot area width
      if (plotContainer) {
        plotContainer.style.width = `calc(100% - ${newWidth}px)`;
      }
    });

    document.addEventListener("mouseup", () => {
      if (isResizing) {
        isResizing = false;
        document.body.classList.remove("sidebar-resizing");
      }
    });
  },
};

export default ResizableSidebar;
