# Ability to triage issues and PRs

Trusted members of the repository can use this workflow to triage issues and PRs by writing next commands:
- `/triage` - adds the `needs-triage` label to the issue or PR. That should be used when user is unsure about adding a feature or closing the issue.
- `/triageoff` - removes the `needs-triage` label from the issue or PR. Label should be present
- `/np wontfix` - closes the issue with not planned status and tagging with 'wontfix' label.
- `/np notrelated` - closes the issue with not planned status and tagging with 'not related' label. Used in cases when the issue is not related to the project.
- `/np <any word>` - closes the issue with not planned status.
- `/duplicate <issue number>` - closes the issue with duplicate status. GH API is bugged, so it won't add issue number to status, but GH Actions will leave a comment.

Any of this command will delete your message leave a log by GH Actions to avoid any possible sabotage.

# Notes for future

- No, custom labels won't be supported due to maintaining clean structure of project.
- To become able to use this workflow, you should be a trusted member and included directly by owner of project or by PR from other trusted member.
- Any abuse of this workflow can and will lead to revoking of your access to this workflow and/or banning from the project.
- Note for Chris: I wanted to make something similar for discussions, but GH API has no docs for it, so result is next - triage for both issues and PRs and ability to close stupid issues from people who can't read.

# Known bugs

- I'm too lazy to make a proper check for command being at the start of the message, so if you write something like "I think this is a duplicate /duplicate 123" it will still work and your message will be deleted. So please write your comment and command in separate messages. If someone fixes this, delete this note.
- Writing "/np" without any word won't work because of regex, so please write `/np <any word>` instead of just "/np". If someone fixes this, delete this note.
