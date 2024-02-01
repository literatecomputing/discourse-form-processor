export default function () {
  this.route("forms", function () {
    window.console.log("doing a route!");
    this.route("submit", { path: "/forms/submit/:id" });
  });
  this.route("get", { path: ":id" });
}
