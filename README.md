# TADL Incident Database

Staff-only incident reporting, patron records, suspensions, and historical incident reports.

## Development

Install Ruby from [.ruby-version](.ruby-version), PostgreSQL, and libvips. Use a local PostgreSQL role with permission to create development and test databases. Set `DATABASE_URL` explicitly when you want to use a different local database. Use synthetic records in development and tests.

```sh
bundle install
bin/rails db:prepare
bin/rails server --binding 127.0.0.1
bin/rails test
```

Copy [.env_sample](.env_sample) to `.env` for local Google sign-in. Use a development Google OAuth client registered for `http://localhost:3000/auth/google_oauth2/callback` and set `AUTH_DOMAIN` to the allowed Google Workspace domain. Set the individual staff role lists in the same file. The tests exercise sign-in with synthetic Google identities and require no OAuth credentials. Run `bin/rails test:system` with Chrome installed to verify the browser workflow. Development uses local job processing with email delivery disabled.

Staff create draft and published reports with free-form behavior descriptions. Earlier A/B rules and imported reports remain readable as historical records. Active Storage originals, thumbnails, and letters require a staff session. Drafts and their attachments are limited to the author and users on the incident editor list.

## Deployment

See the [Dokku deployment and cutover runbook](docs/deployment.md) for the web and worker processes, isolated staging, PostgreSQL and attachment transfer, and proxy and certificate validation.
