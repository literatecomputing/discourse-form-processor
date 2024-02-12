import Component from "@glimmer/component";
// import { clipboardCopy } from "discourse/lib/utilities";
import User from "discourse/models/user";

export default class FormSubmissionLink extends Component {
  constructor() {
    super(...arguments);
    this.id = this.args.id || 0;
    this.topic = this.args.topic;
    this.formFields = this.topic.form_fields;
    this.currentUser = User.current();
  }

  get formSubmissionText() {
    const capitalizeFirstLetter = (str) =>
      `${str.charAt(0).toUpperCase()}${str.slice(1)}`;
    window.console.log("formsubmittionlink this", this);
    window.console.log("currentUser", this.currentUser);
    // window.console.log("my topic!!", this.topic);
    let formText = `\n<form action="${window.location.origin}/forms/submit/${this.id}" method="POST">`;
    formText += `\n<input type="hidden" name="success_url" id="_success_url" value="https://google.com/search?q=success">`;
    formText += `\n<input type="hidden" name="pm_user" id="pm_user" value="${this.currentUser.username}">`;
    formText += `\n<input type="hidden" name="debug_mode" id="debug_mode" value=True>`;
    window.console.log("formFields!", this.formFields);
    for (const field of this.formFields) {
      // formText += `Field: ${field}\n`;
      if (field.endsWith("s")) {
        formText += `\n<div class="form-group-radio">
<legend>${capitalizeFirstLetter(field)}</legend>
  ${field}1 description<br>
  <input type="checkbox" id="${field}1" name="${field}[]" value="${field}1">
  <label for="${field}1">${field}2 label</label><br>
  ${field} description<br>
  <input type="checkbox" id="${field}2" name="${field}[]" value="${field}2">
<label for="${field}2">${field}2 label</label><br>
</div>`;
      } else if (field.includes("message")) {
        formText += `\n<div class="form-group">
  <label for="message">Tell us more about what you need</label>
  <textarea id="message" name="message" placeholder="Your message goes here" style="height:8rem"></textarea>
</div>`;
      } else {
        formText += `\n<div class="form-group">
  <label for="${field}">${capitalizeFirstLetter(field)}</label>
  <input type="text" id="${field}" name="${field}" placeholder="Your ${field} placeholder" required>
</div>`;
      }
    }
    formText += `\n<input class="button" type="submit" value="Submit">`;
    formText += `\n</form>`;
    return formText;
  }
  get siteUrl() {
    return window.location.origin;
  }
}
