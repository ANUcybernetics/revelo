// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Hooks from "./hooks";

let params = {
  _csrf_token: document
    .querySelector("meta[name='csrf-token']")
    .getAttribute("content"),
};

if (localStorage.getItem("revelo_anon_user_id")) {
  params.anon_user_id = localStorage.getItem("revelo_anon_user_id");
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  longPollFallbackMs: 2500,
  params: params,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Allows to execute JS commands from the server
window.addEventListener("phx:js-exec", ({ detail }) => {
  document.querySelectorAll(detail.to).forEach((el) => {
    liveSocket.execJS(el, el.getAttribute(detail.attr));
  });
});

function highContrastExpected() {
  return localStorage.theme === "high_contrast";
}

function initHighContrast() {
  // On page load or when changing themes, best to add inline in `head` to avoid FOUC
  if (highContrastExpected())
    document.documentElement.classList.add("high_contrast");
  else document.documentElement.classList.remove("high_contrast");
}

window.addEventListener("toggle-high-contrast", (e) => {
  if (highContrastExpected()) localStorage.theme = "light";
  else localStorage.theme = "high_contrast";
  initHighContrast();
});

initHighContrast();
