export const RelationshipScroll = {
  updated() {
    const scrollArea = this.el.querySelector(".salad-scroll-area");
    if (scrollArea) {
      scrollArea.scrollTop = 0;
    }
  },
};

export default RelationshipScroll;
