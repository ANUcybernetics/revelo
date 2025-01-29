export const AnonUser = {
  mounted() {
    // Get existing ID from localStorage
    const anonUserId = localStorage.getItem("revelo_user_id");

    // Send to server
    this.pushEvent("check_anon_user", { anon_user_id: anonUserId });

    // Listen for new user creation
    this.handleEvent("store_anon_user", ({ user_id }) => {
      localStorage.setItem("revelo_user_id", user_id);
    });
  },
};

export default AnonUser;
