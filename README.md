# **Plugin Name** Plugin

**Plugin Summary**

For more information, please see: **url to meta topic**

## TODO

- 1 make it easier to find forms and data
- 1 instead of direct redirect, push an HTML page with branding that redirects after 5-10 seconds
- 1 see that there is a reason for every failure
- 2 change pm_user to something like formhoster_user. Also, consider using userid instead of username?
- 2 consider: add an endpoint at something like `https://getform.io/f/mbkyQrez` that allows "all" variables.
- 2 add honeypot like `<input type="hidden" name="_gotcha" style="display:none !important">`. 
- 2 get honeypot ideas from https://blog.stefanolaru.com/how-to-make-the-honeypot-field-more-effective
- 2 don't let them copy code if they aren't in the group
- 1 make better sense of what debug mode should look like -- maybe don't send PM except to self?
- 2 do something about processing forms if user is not in group
- 2 slack notifications https://api.slack.com/methods/chat.postMessage
- 2 zapier push
- 2 add a route that presents form data like https://app.getform.io/forms/mbkyQrez
- 2 allow create PM button only if in PM group
- 2 see if it's possible to use jekyll integrations for some other stuff
- 2 make group that allows teams (adding to team group creates user-team group and private category)
- 3 include user in PM if logged in (ON hold. Impossible?)
- 3 remove allowed referrer as site setting
- 3 add possibility for comments, or other notation in templates
- 3 checkbox/setting to disable jekyll frontmatter
- 3 consider a javascript form like https://formkeep.com/forms/484a605174cc/submissions/23705224?spam=false
- add custom field for customized forms
- DONE. copy button for sample forms
- DONE. make copy button for form code
- DONE? figure out why actions are not running (??)
- DONE. display number of total and monthly forms.
- DONE. control access by group
- DONE. security: check that user has read access to the topic
- DONE. setting to determine what user sends the PM
- DONE. add user custom field for allowed referrers
- DONE. add optional TITLE: in body (raw) rather than using the title
- DONE.tell user to add allowed referrers
- DONE. create user custom field for each form filled out
- DONE. add number of completed forms to current_user serializer
- DONE. add number of completed forms in current month to current_user serializer
- DONE. form pms get a tag


### Specs

- make sure that the code copy buttons work
- DONE. form_data added to submitted forms
- DONE. form_fields added to form templates
- check? user record includes referrer url field
- DONE template check -- category and tag (allow tag in other categories?)
- DONE allowed referrers added to profile
- example form available if it's a form
- DONE submit to /forms/submit/:id -- user check (group, user exists, ...)
- DONE submit to /forms/submit/:id -- referrer check (just user fields)
- submit to /forms/submit/:id -- fields check
- form_processor_pm_allowed_groups make sure that's the group that can use PMs
- specs for form submission (look at webhook specs)

