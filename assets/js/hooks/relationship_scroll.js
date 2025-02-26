export const RelationshipScroll = {
  mounted() {
    this.handleEvent("page_changed", () => {
      console.log("changed");
      // Find the scroll area in the parent component
      const scrollArea = document.querySelector(".salad-scroll-area");
      if (scrollArea) {
        scrollArea.scrollTop = 0;
      }
    });
  },
};

export default RelationshipScroll;
