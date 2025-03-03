import cytoscape from "cytoscape";
import coseBilkent from "cytoscape-cose-bilkent";

cytoscape.use(coseBilkent);

const keySVG = encodeURIComponent(`
  <svg width="34" height="25" viewBox="0 0 34 25" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="33.3333" height="25" rx="12.5" fill="#BAE6FD"/>
  <path fill-rule="evenodd" clip-rule="evenodd" d="M19.2708 5.20837C16.682 5.20837 14.5833 7.30704 14.5833 9.89587C14.5833 10.1693 14.6068 10.4376 14.6519 10.6989C14.6986 10.969 14.6297 11.1963 14.4984 11.3276L9.98519 15.8408C9.59449 16.2315 9.375 16.7614 9.375 17.3139V19.2709C9.375 19.5585 9.60819 19.7917 9.89583 19.7917H12.5C12.7876 19.7917 13.0208 19.5585 13.0208 19.2709V18.2292H14.0625C14.3501 18.2292 14.5833 17.996 14.5833 17.7084V16.6667H15.625C15.7631 16.6667 15.8956 16.6118 15.9933 16.5142L17.8391 14.6683C17.9704 14.537 18.1977 14.4681 18.4678 14.5148C18.7291 14.5599 18.9974 14.5834 19.2708 14.5834C21.8597 14.5834 23.9583 12.4847 23.9583 9.89587C23.9583 7.30704 21.8597 5.20837 19.2708 5.20837ZM19.2708 7.29171C18.9832 7.29171 18.75 7.52489 18.75 7.81254C18.75 8.10019 18.9832 8.33337 19.2708 8.33337C20.1338 8.33337 20.8333 9.03293 20.8333 9.89587C20.8333 10.1835 21.0665 10.4167 21.3542 10.4167C21.6418 10.4167 21.875 10.1835 21.875 9.89587C21.875 8.45763 20.7091 7.29171 19.2708 7.29171Z" fill="#082F49"/>
  </svg>
`);

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
      "font-weight": function (ele) {
        return ele.data("isKey") ? "600" : "400";
      },
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
            "background-image": function (ele) {
              return ele.data("isKey")
                ? `data:image/svg+xml;utf8,${keySVG}`
                : "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
            },
            "background-width": function (ele) {
              return ele.data("isKey") ? "50px" : "0";
            },
            "background-height": function (ele) {
              return ele.data("isKey") ? "37px" : "0";
            },
            "background-position-x": function (ele) {
              return ele.data("isKey") ? "4px" : "0";
            },
            "background-position-y": function (ele) {
              return ele.data("isKey") ? "4px" : "0";
            },
            "background-fit": "none",
            "background-clip": "none",
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
            "text-margin-y": function (ele) {
              return ele.data("isKey") ? 15 : 0;
            },
            "text-outline-opacity": 1,
            "font-family": "Inter",
            "font-weight": function (ele) {
              return ele.data("isKey") ? "600" : "400";
            },
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
