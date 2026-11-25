# TADL Incident Database

Traverse Area District Library staff use this app to document incidents, maintain patron records, track suspensions, and look up historical reports. Staff sign in with a verified Google Workspace account from the configured domain.

Browse and search results offer page controls above and below longer lists and carry the selected view or search filters to the next page.

## Incident reports

- Choose **New incident** to record a title, date and time in Eastern time, location, and description. Photos and patron links are optional. Both **Save as draft** and **Publish incident** require the report fields.
- Use **Add patron** to find an existing record or create one. On a new report, you can choose patrons and enter a **Violation summary** before completing the report. New patrons and links are saved together with the draft or published report.
- Open the report to edit or publish a draft later. **Publish incident** makes the report visible to signed-in staff and queues a staff notice. Use **Update incident** for an already published report. **Cancel** discards unsaved form changes. On an existing report, actions such as linking a patron, saving a patron edit or suspension, or confirming photo removal take effect separately from saving the report.
- Browse **All incidents**, **My incidents** for your published reports, and **My drafts** for your own drafts. Search published reports by report number, title, description, linked patron details, violation notes, or incident comments. Open a report by its title or thumbnail.
- Edit per-patron behavior notes as free text in **Violation summary**. Earlier A/B violation entries remain visible on historical reports. Removing a patron link also removes that incident’s notes and any suspension and letter for that patron. The patron record and its other incident links stay available.

## Patron records

- Record a patron’s name or alias, address, library card number, description, and photos. At least one name field or an alias is required. Staff can edit an existing patron from the patron detail page or from an incident they can edit.
- Browse **All patrons**, **Suspended**, and **Call 911**. **Search** matches names, aliases, descriptions, and patron comments. **Only patrons with an unknown name** finds records with blank name fields, including patrons identified by an alias.
- A patron’s detail page shows their published incident history, behavior notes, suspension dates and available letters, photos, and comments. Patron records are shared with signed-in staff once saved, including records created while saving an incident draft.

## Suspensions and letters

- In the incident editor, staff with suspension permission can choose **Suspend patron** or **Edit suspension** for a linked patron. Set an end date and, where applicable, record **Call 911 if seen on library property**. Each patron can have one suspension per incident and overlapping suspensions across incidents.
- Open **Patrons**, then **Suspended**, to choose **Suspension List** or **Suspension Calendar**. The calendar shows upcoming dates, including today, and links to each patron’s record. When a patron has overlapping published suspensions, the calendar uses their latest end date.
- The **Suspension List** and **Call 911** views use published incidents and end dates after today in Eastern time. A patron’s **Suspended until** summary shows the latest active end date. An active Call 911 flag on any of their suspensions triggers the alert. Draft and expired suspensions retain the recorded flag in the individual incident details.
- Prepare and mail the suspension letter outside the app. **Add Suspension Letter** accepts one optional PDF up to 5 MiB when issuing or editing the suspension. **Letter Sent** records the mailing status manually. Authorized staff can download the letter from the incident or its entry on the patron record.
- Removing an attached PDF retains the suspension and its mailed status. **Revoke Suspension** removes the suspension and its letter. Removing a patron link that has a suspension also requires suspension permission.

## Comments

**Extra information** on incident and patron detail pages is for staff comments. Comments show the author and time, and saving takes you back to the updated entry. Staff can edit or delete their own comments.

## Photos and attachments

- Incident reports and patron records accept multiple JPEG or PNG uploads up to 10 MiB per image. Photo thumbnails on detail pages open a lightbox with a link to the original. The lightbox closes with its close button, Escape, or a click outside it.
- Originals, thumbnails, and PDFs served by the app require a staff session. Incident photos and suspension letters also follow the linked incident’s access rules. Public Active Storage URLs are disabled.

## Legacy reports

**Legacy** is a read-only archive of imported incident reports. Browse the archive or search by original report number, title, description, staff narrative, patron name, or submitter. The detail page shows archived photos, A/B codes, and suspension duration when recorded.

## Permissions and record removal

Signed-in staff can file reports, view published reports and the legacy archive, maintain standalone patron records, and comment on records they can access. Incident authors can view and edit their own drafts and published reports and delete their own unpublished reports.

Additional permissions are independent comma-separated staff email lists.

| Setting | Permission |
| --- | --- |
| `CAN_EDIT` | View other authors’ drafts and edit their incident reports. **My drafts** still lists only your own drafts. |
| `CAN_SUSPEND` | Create, edit, and revoke suspensions and manage their letters. The controls are in the incident editor. |
| `SUPER_ADMIN` | Delete incident reports and patron records. Incident editing and suspension permissions are granted separately. |

Edit and delete actions are available from record detail pages when permitted. Eligible users can also delete an incident from its editor. Destructive actions use confirmation dialogs. Deleting an incident removes its comments, photos, violation notes, suspensions, and letters, and unlinks its patrons. Deleting a patron removes their photos, comments, violation notes, suspensions, and letters, and unlinks them from incident reports.

## Staff notifications

| Event | Recipients | Timing |
| --- | --- | --- |
| New incident | `EMAIL_TO` | First publication, including publishing a saved draft. |
| New suspension | `EMAIL_TO` | Once the suspension is active and its incident is published. |
| Suspension expired | `UNSUSPEND_EMAIL_TO`, or `CAN_SUSPEND` if unset | The day after the recorded end date of a patron’s latest published suspension. |
| New comment | `COMMENT_EMAIL_TO` | A new comment on a published incident or a patron record. |

Messages include HTML and plain text, record links, and subjects that identify the event. New incident subjects include the title and report number so reports with the same title have distinct subjects. Report notices are sent only on first publication, and comment notices only when the comment is added. A letter attached when a new suspension notice is sent is available through a staff-only link. A later upload appears on the record without resending the notice.

Incident and suspension notices can include small inline photo thumbnails that render without signing in to the app. Those copies are part of the email. Links to originals and suspension letters still require staff sign-in.

Set `UNSUSPEND_EMAIL_TO` to a comma-separated list to override the recipients of expiration notices, or set it to an empty value to turn off those notices. Leave it unset to follow changes to the `CAN_SUSPEND` staff list.

## Development

The app uses Rails 8.1, PostgreSQL for records and full-text search, and libvips for image thumbnails. Install Ruby from [.ruby-version](.ruby-version) and use a local PostgreSQL role with permission to create development and test databases. Set `DATABASE_URL` explicitly to choose a different local database. Use synthetic records in development and tests.

Copy [.env_sample](.env_sample) to `.env` for local Google sign-in. Use a development Google OAuth client registered for `http://localhost:3000/auth/google_oauth2/callback`, set `AUTH_DOMAIN` to the allowed Workspace domain, and configure the staff permissions you want to exercise. Development uses local job processing with email delivery disabled.

```sh
bundle install
bin/rails db:prepare
bin/rails server --binding 127.0.0.1
```

The test suite uses synthetic Google identities and needs no OAuth credentials. Install Chrome to run the browser tests.

```sh
bin/rails test
bin/rails test:system
```

## Deployment

The [Dockerfile](Dockerfile) and [Procfile](Procfile) build and run the app on Dokku. Puma serves the web app, Sidekiq uses Redis for queued work and scheduled suspension checks, and PostgreSQL stores the records. Both processes use the same persistent Active Storage volume. The release task runs database migrations, and `/up` is the health endpoint.

Production uses `APP_HOST` for canonical HTTPS links and `AUTH_DOMAIN`, `GOOGLE_CLIENT_ID`, and `GOOGLE_CLIENT_SECRET` for Google sign-in. Set `EMAIL_FROM`, `EMAIL_TO`, `COMMENT_EMAIL_TO`, `SMTP_USERNAME`, and `EMAIL_PASSWORD` for Gmail SMTP delivery. `MAIL_DELIVERY_ENABLED=false` disables delivery for environments that should not send notifications.

The [Dokku deployment and cutover runbook](docs/deployment.md) covers service setup, staging, PostgreSQL and file migration, and proxy and TLS verification.
