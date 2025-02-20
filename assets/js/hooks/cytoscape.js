import cytoscape from "cytoscape";

export const Cytoscape = {
  mounted() {
    this.cy = cytoscape({
      container: this.el,
      elements: [],
      style: [
        {
          selector: "node",
          style: {
            "background-color": "#666",
            label: "data(name)",
          },
        },
        {
          selector: "edge",
          style: {
            width: 3,
            "line-color": "#ccc",
            "target-arrow-color": "#ccc",
            "target-arrow-shape": "triangle",
            "curve-style": "bezier",
          },
        },
      ],
      layout: {
        name: "circle",
      },
    });

    this.cy.on("tap", "node", (event) => {
      const node = event.target;
      this.pushEventTo(this.el, "node_clicked", {
        id: node.id(),
      });
    });
  },

  updated() {
    const elements = JSON.parse(this.el.dataset.elements || "[]");
    const layout = JSON.parse(this.el.dataset.layout || "{}");

    this.cy.elements().remove();
    this.cy.add(elements);

    if (layout.name) {
      const l = this.cy.layout(layout);
      l.run();
    }

    this.cy.fit();
  },

  destroyed() {
    if (this.cy) {
      this.cy.destroy();
    }
  },
};

export default LoopGraph;
