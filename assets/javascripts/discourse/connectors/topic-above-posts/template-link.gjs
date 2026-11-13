import Component from "@glimmer/component";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import FormSubmissionLink from "../../components/form-submission-link.gjs";

export default class TemplateLink extends Component {
  @service currentUser;

  <template>
    {{#if @outletArgs.model.form_data.id}}
      {{#if this.currentUser.forms_processed}}
        <div class="form-counter">
          {{this.currentUser.forms_processed}}
          forms processed by FormMaster,
          {{this.currentUser.forms_processed_this_month}}
          this month.
        </div>
      {{/if}}
      <LinkTo @model={{@outletArgs.model.form_data.id}} @route="topic">
        {{i18n "discourse_form_processor.visit_template_topic"}}
      </LinkTo>
    {{/if}}

    {{#if @outletArgs.model.is_template_topic}}
      {{#if this.currentUser.forms_processed}}
        <div class="form-counter">
          {{this.currentUser.forms_processed}}
          forms processed by FormMaster,
          {{this.currentUser.forms_processed_this_month}}
          this month.
        </div>
      {{/if}}
      {{#if this.currentUser.form_allowed_referrers}}
        <div class="allowed-referrers">
          {{i18n "discourse_form_processor.allowed_referrers"}}:
          {{this.currentUser.form_allowed_referrers}}
        </div>
      {{else}}
        <div class="missing-referrers alert">
          {{dIcon "far-eye"}}
          {{i18n "discourse_form_processor.missing_referrers_pre_link"}}
          <LinkTo @model={{this.currentUser}} @route="preferences.profile">
            {{dIcon "cog"}}
            <span class="item-label">
              {{i18n "user.preferences"}}
            </span>
          </LinkTo>
          {{i18n "discourse_form_processor.missing_referrers_post_link"}}
        </div>
      {{/if}}
      <FormSubmissionLink
        @id={{@outletArgs.model.id}}
        @topic={{@outletArgs.model}}
      />
    {{/if}}
  </template>
}
