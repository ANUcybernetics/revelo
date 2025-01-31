export const UpdateGenerateValue = {
  mounted() {
    this.el.addEventListener("input", (e) => {
      const button = document.querySelector("#generate_variables_button");
      button.setAttribute("phx-value-count", e.target.value);
    });
  },
};

export default UpdateGenerateValue;
