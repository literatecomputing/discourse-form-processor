# frozen_string_literal: true

# Submissions used to be recorded as one `submitted_form_<topic_id>` user custom field
# each, which hits core's 100-custom-fields-per-user cap. Counts now come from the PMs.
class DeleteSubmittedFormUserCustomFields < ActiveRecord::Migration[7.0]
  def up
    execute "DELETE FROM user_custom_fields WHERE name LIKE 'submitted\\_form\\_%'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
