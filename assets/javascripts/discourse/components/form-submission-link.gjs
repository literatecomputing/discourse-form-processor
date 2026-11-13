import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import discourseDebounce from "discourse/lib/debounce";
// import { clipboardCopy } from "discourse/lib/utilities";
import User from "discourse/models/user";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";

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

  get formSubmissionText() {
    let formText = this.formTextCode();
    return formText;
  }

  get siteUrl() {
    return window.location.origin;
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
    form += `\n<input type="hidden" name="formhoster_user" id="formhoster_user" value="${this.currentUser.username}">`;
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

  <template>
    {{#if this.formFields}}
      {{#if this.currentUser}}
        <div class="html-example alert-info">
          <details>
            <summary>{{i18n "discourse_form_processor.view_template"}}</summary>
            <pre class="form-html">
              {{this.formSubmissionText}}
            </pre>
          </details>
        </div>
        <DButton
          class={{dConcatClass
            "btn-default"
            "template-copy"
            (if this.copyConfirm "ok")
          }}
          @action={{this.copy}}
          @icon={{if this.copyConfirm "check" "copy"}}
          @label="discourse_form_processor.copy_template"
        />
        <DButton
          class="template-new-topic"
          @action={{this.createNewTopic}}
          @icon="plus"
          @label="discourse_form_processor.create_template_pm"
          @translatedTitle={{i18n
            "discourse_form_processor.create_template_title"
            tag=this.topic.form_pm_tag
          }}
        />
      {{/if}}
    {{/if}}
  </template>
}
