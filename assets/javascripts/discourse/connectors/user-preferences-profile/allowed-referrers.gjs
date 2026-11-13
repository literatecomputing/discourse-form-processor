import Component from "@glimmer/component";
import { Input } from "@ember/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class AllowedReferrers extends Component {
  @service siteSettings;

  <template>
    {{#if this.siteSettings.form_processor_enabled}}
      <div class="control-group allowed-referrers">
        <label class="control-label">{{i18n
            "discourse_form_processor.allowed_referrers"
          }}</label>
        <div class="controls bio-composer input-xxlarge">
          <label class="text-label"></label>
          <Input
            class="input-xxlarge"
            @type="text"
            @value={{@outletArgs.model.custom_fields.allowed_referrers}}
          />
          <div class="control-instructions">
            {{i18n "discourse_form_processor.allowed_referrers_description"}}
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
