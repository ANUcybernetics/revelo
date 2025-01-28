export const StoreUserID = {
  mounted() {
    this.handleEvent("store_user_id", ({ user_id }) =>
      this.storeUserId(user_id),
    );
    this.handleEvent("restore_user_id", () => this.restoreUserId());
    this.handleEvent("clear_user_id", () => this.clearUserId());
  },

  storeUserId(user_id) {
    localStorage.setItem("user_id", user_id);
  },

  restoreUserId() {
    const user_id = localStorage.getItem("user_id");
    this.pushEvent("restore_user_id", user_id);
  },

  clearUserId() {
    localStorage.removeItem("user_id");
  },
};
