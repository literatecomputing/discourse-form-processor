import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
// import { clipboardCopy } from "discourse/lib/utilities";
import User from "discourse/models/user";
import discourseDebounce from "discourse-common/lib/debounce";

export default class FormSubmissionLink extends Component {
  // }
  @service composer;

  @tracked copyConfirm = false;
  constructor() {
    super(...arguments);
    this.id = this.args.id || 0;
    this.topic = this.args.topic;
    this.formFields = this.topic.form_fields;
    this.currentUser = User.current();
  }

  //   static shouldRender(outletArgs, helper) {
  //   return outletArgs.model.is_template && helper.currentUser?.can_create_topic;

  formTextCode() {
    const capitalizeFirstLetter = (str) =>
      `${str.charAt(0).toUpperCase()}${str.slice(1)}`;
    let form = `\n---\nlayout: page\ntitle: ${this.topic.title}\npermalink: /contact/\n`;
    form += `formhoster_url: ${window.location.origin}/${this.topic.slug}/${this.topic.id}\n`;
    form += `formhoster_endpoint: ${window.location.origin}/forms/submit/${this.topic.id}\n`;
    form += `---\n\n`;
    form += '\n<div class="formhoster-form">';
    form += `\n<form action="${window.location.origin}/forms/submit/${this.id}" method="POST">`;
    form += `\n<input type="hidden" name="success_url" id="_success_url" value="${window.location.origin}/pub/success">`;
    form += `\n<input type="hidden" name="pm_user" id="pm_user" value="${this.currentUser.username}">`;
    form += `\n<input type="hidden" name="debug_mode" id="debug_mode" value=True>`;

    for (const field of this.formFields) {
      if (field.endsWith("s")) {
        form += `\n<div class="form-group-radio">
<legend>${capitalizeFirstLetter(field)}</legend>
  ${field}1 description<br>
  <input type="checkbox" id="${field}1" name="${field}[]" value="${field}1">
  <label for="${field}1">${field}2 label</label><br>
  ${field} description<br>
  <input type="checkbox" id="${field}2" name="${field}[]" value="${field}2">
<label for="${field}2">${field}2 label: </label><br>
</div>`;
      } else if (field.includes("message")) {
        form += `\n<div class="form-group">
  <label for="message">Your ${field}: </label>
  <textarea id="message" name="message" placeholder="Your message goes here" style="height:8rem"></textarea>
</div>`;
      } else {
        form += `\n<div class="form-group">
  <label for="${field}">${capitalizeFirstLetter(field)}</label>
  <input type="text" id="${field}" name="${field}" placeholder="Your ${field} placeholder" required>
</div>`;
      }
    }

    form += `\n<input class="button" type="submit" value="Submit">`;
    form += `\n</form>`;
    form += "\n</div>";
    return form;
  }

  get formSubmissionText() {
    let formText = this.formTextCode();
    return formText;
  }
  get siteUrl() {
    return window.location.origin;
  }

  async fetchRaw() {
    return await ajax(`/raw/${this.topic.id}/1`, { dataType: "text" });
  }

  @action
  async createNewTopic() {
    const text = await this.fetchRaw();
    this.composer.openNewMessage({
      body: text,
      title: `Copy of ${this.topic.title}`,
      recipients: this.currentUser.username,
      tags: [this.topic.form_pm_tag], // this doesn't work
    });
  }

  @action
  async copy() {
    const text = await this.formTextCode();
    navigator.clipboard.writeText(text);
    this.copyConfirm = true;
    discourseDebounce(this.resetCopyButton, 2000);
  }
  @action
  resetCopyButton() {
    this.copyConfirm = false;
  }
}
