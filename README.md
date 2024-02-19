# **Plugin Name** Plugin

**Plugin Summary**

For more information, please see: **url to meta topic**

## TODO

- DONE. control access by group
- count number of forms processed.  with user actions? Some other way?
- DONE. security: check that user has read access to the topic
- include user in PM if logged in
- DONE. setting to determine what user sends the PM
- DONE. add user custom field for allowed referrers
- remove allowed referrer as site setting
- copy button for sample forms
- DONE. add optional TITLE: in body (raw) rather than using the title
- add possibility for comments, or other notation in templates
- tell user to add allowed referrers
- create user custom field for each form filled out
- add number of completed forms to current_user serializer
- add number of completed forms in current month to current_user serializer
- make a "thanks" page with link to their redirect page for free users

### Specs

- form_data added to submitted forms
- form_fields added to form templates
- user record includes referrer url field
- is_form_template defined (not to be confused with is_template from template plugin)
- template check -- category and tag (allow tag in other categories?)
- allowed referrers added to profile
- example form available if it's a form
- submit to /forms/submit/:id -- user check (group, user exists, ...)
- submit to /forms/submit/:id -- referrer check (just user fields)
- submit to /forms/submit/:id -- fields check
- form_processor_pm_allowed_groups make sure that's the group that can use PMs


