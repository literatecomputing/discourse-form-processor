import Controller from "@ember/controller";
// import discourseComputed from "discourse-common/utils/decorators";
import { inject } from "@ember/service";

export default Controller.extend({
  router: inject(),
});
