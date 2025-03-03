import cytoscape from "cytoscape";
import coseBilkent from "cytoscape-cose-bilkent";

cytoscape.use(coseBilkent);

function updateNodeStyles(selectedLoop, loops, cy, relationships) {
  //TODO: Use cytoscape selectors to improve performance
  if (!cy || !selectedLoop) {
    cy?.elements().style({
      opacity: 1,
    });
    return;
  }

  cy.elements().style({
    opacity: 0,
  });

  const selectedLoopNodes = new Set();
  const selectedLoopRelationships = relationships.filter(
    (rel) =>
      rel.group === "edges" &&
      loops.some(
        (loop) =>
          loop.id === selectedLoop &&
          loop.influence_relationships.some(
            (loopRel) => loopRel.id === rel.data.id,
          ),
      ),
  );

  selectedLoopRelationships.forEach((rel) => {
    selectedLoopNodes.add(rel.data.source);
    selectedLoopNodes.add(rel.data.target);
  });

  const selectedLoopRelationshipIds = new Set(
    selectedLoopRelationships.map((rel) => rel.data.id),
  );

  cy.elements().forEach((element) => {
    if (
      selectedLoopRelationshipIds.has(element.id()) ||
      selectedLoopNodes.has(element.id())
    ) {
      element.style({
        opacity: 1,
      });
    }
  });
}

function updateGraphStyles(cy) {
  if (!cy) return;

  const highContrast =
    document.documentElement.classList.contains("high_contrast");

  cy.style()
    .selector("node")
    .style({
      "border-width": highContrast ? "2px" : "1px",
      "border-color": highContrast
        ? "hsl(220, 20%, 65%)"
        : "hsl(220, 13%, 91%)",
      "font-weight": "400",
    })
    .selector('edge[relation = "inverse"]')
    .style({
      "line-color": highContrast
        ? "hsl(213.1, 93.9%, 67.8%)"
        : "hsl(211.7, 96.4%, 78.4%)",
      "target-arrow-color": highContrast
        ? "hsl(213.1, 93.9%, 67.8%)"
        : "hsl(211.7, 96.4%, 78.4%)",
    })
    .selector('edge[relation = "direct"]')
    .style({
      "line-color": highContrast
        ? "hsl(27, 96%, 61%)"
        : "hsl(30.7, 97.2%, 72.4%)",
      "target-arrow-color": highContrast
        ? "hsl(27, 96%, 61%)"
        : "hsl(30.7, 97.2%, 72.4%)",
    })
    .update();
}

export const PlotLoops = {
  mounted() {
    const savedPositions = localStorage.getItem("nodePositions");
    const positions = savedPositions ? JSON.parse(savedPositions) : null;

    this.cy = cytoscape({
      container: this.el,
      elements: JSON.parse(this.el.dataset.elements || "[]"),
      style: [
        {
          selector: "node",
          style: {
            "background-color": "#ffffff",
            "border-width": function (ele) {
              const highContrast =
                document.documentElement.classList.contains("high_contrast");
              return highContrast ? "2px" : "1px";
            },
            "border-color": function (ele) {
              const highContrast =
                document.documentElement.classList.contains("high_contrast");
              return highContrast ? "hsl(220, 20%, 65%)" : "hsl(220, 13%, 91%)";
            },
            "border-style": "solid",
            label: "data(label)",
            "text-wrap": "wrap",
            "text-max-width": "250px",
            "font-size": "24px",
            "text-valign": "center",
            "text-halign": "center",
            "text-outline-width": 0,
            padding: "18px",
            shape: "round-rectangle",
            width: "300px",
            height: function (ele) {
              return ele.data("label").length * 0.5 + 30;
            },
            "text-margin-y": 0,
            "text-outline-opacity": 1,
            "font-family": "Inter",
            "font-weight": "400",
          },
        },
        {
          selector: "edge",
          style: {
            width: 8,
            "line-color": "data(relation)",
            "target-arrow-color": "data(relation)",
            "target-arrow-shape": "triangle",
            "curve-style": "unbundled-bezier",
          },
        },
        {
          selector: 'edge[relation = "inverse"]',
          style: {
            "line-color": function (ele) {
              const highContrast =
                document.documentElement.classList.contains("high_contrast");
              return highContrast
                ? "hsl(213.1, 93.9%, 67.8%)"
                : "hsl(211.7, 96.4%, 78.4%)";
            },
            "target-arrow-color": function (ele) {
              const highContrast =
                document.documentElement.classList.contains("high_contrast");
              return highContrast
                ? "hsl(213.1, 93.9%, 67.8%)"
                : "hsl(211.7, 96.4%, 78.4%)";
            },
          },
        },
        {
          selector: 'edge[relation = "direct"]',
          style: {
            "line-color": function (ele) {
              const highContrast =
                document.documentElement.classList.contains("high_contrast");
              return highContrast
                ? "hsl(27, 96%, 61%)"
                : "hsl(30.7, 97.2%, 72.4%)";
            },
            "target-arrow-color": function (ele) {
              const highContrast =
                document.documentElement.classList.contains("high_contrast");
              return highContrast
                ? "hsl(27, 96%, 61%)"
                : "hsl(30.7, 97.2%, 72.4%)";
            },
          },
        },
      ],
      layout: positions
        ? {
            name: "preset",
            positions: positions,
          }
        : {
            name: "cose-bilkent",
            quality: "proof",
            animate: false,
            randomize: true,
            nodeDimensionsIncludeLabels: true,
            fit: true,
            padding: 50,
            nodeRepulsion: 8000,
            idealEdgeLength: 200,
            edgeElasticity: 0.45,
            nestingFactor: 0.1,
            gravity: 0.25,
            numIter: 2500,
            tile: false,
            tilingPaddingVertical: 20,
            tilingPaddingHorizontal: 20,
            gravityRangeCompound: 1.5,
            gravityCompound: 1.0,
            gravityRange: 3.8,
            initialEnergyOnIncremental: 0.5,
          },
    });

    window.addEventListener("toggle-high-contrast", () => {
      setTimeout(() => updateGraphStyles(this.cy), 0);
    });

    // Save positions when nodes are moved
    this.cy.on("position", "node", () => {
      const positions = {};
      this.cy.nodes().forEach((node) => {
        positions[node.id()] = node.position();
      });
      localStorage.setItem("nodePositions", JSON.stringify(positions));
    });

    this.cy.on("tap", "edge", (event) => {
      const edge = event.target;
      const edgeId = edge.id();

      // Send the clicked edge ID to the LiveView component
      this.pushEventTo(
        this.el.dataset.target || "#loop-table",
        "edge_clicked",
        {
          id: edgeId,
        },
      );
    });

    this.el.addEventListener("loop-selected", (event) => {
      const loopId = event.detail.loopId;
      this.el.dataset.selectedLoop = loopId || "";

      const loops = JSON.parse(this.el.dataset.loops || "[]");
      const elements = JSON.parse(this.el.dataset.elements || "[]");

      updateNodeStyles(
        loopId,
        loops,
        this.cy,
        elements.filter((ele) => ele.group === "edges"),
      );
    });
  },

  updated() {
    const elements = JSON.parse(this.el.dataset.elements || "[]");
    const selectedLoop = this.el.dataset.selectedLoop;
    const loops = JSON.parse(this.el.dataset.loops || "[]");

    // Update the elements in the graph to match the data
    this.cy.elements().remove();
    this.cy.add(elements);

    // Apply the saved positions if they exist
    const savedPositions = localStorage.getItem("nodePositions");
    const positions = savedPositions ? JSON.parse(savedPositions) : null;

    if (positions) {
      this.cy.nodes().forEach((node) => {
        if (positions[node.id()]) {
          node.position(positions[node.id()]);
        }
      });
    }

    updateGraphStyles(this.cy);

    // Update styles for selected loop
    updateNodeStyles(
      selectedLoop,
      loops,
      this.cy,
      elements.filter((ele) => ele.group === "edges"),
    );
  },

  destroyed() {
    window.removeEventListener("toggle-high-contrast", () => {
      updateGraphStyles(this.cy);
    });

    if (this.cy) {
      this.cy.destroy();
    }
  },
};

export default PlotLoops;
