# Operations Playbook

How to run and maintain the site.

# Deployment

## Environment configuration

We configure the deployment using [Heroku environment variables](https://dashboard.heroku.com/apps/adopt-a-drain-mrwa/settings). The maps API keys are all set to same API key from the Google Maps console, and the mailserver fields are set using the mailgun configuration. 

```sh
GOOGLE_MAPS_JAVASCRIPT_API_KEY=<your key>
GOOGLE_GEOCODER_API_KEY=<your key>
GOOGLE_MAPS_KEY=<your key>
MAILSERVER_HOST=<your key>
MAILSERVER_DOMAIN=<your key>
MAILSERVER_USERNAME=<your key>
MAILSERVER_PASSWORD=<your key>
```

## Deploying

`git push heroku master`

# Database

Initially, set up the db schema:

`heroku run rake db:schema:load`

Then, whenever migrations are added, load them:

`heroku run rake db:migrate`

# Set Up a New City

1. Add a configuration file under `config/cities`. The name of the file is used as the id of the city.
2. Generate a logo using the `generate-logos` script
3. Add drain data under `config/cities/data` and reference it in the city config.
4. claim the domain with heroku
```bash
heroku domains:add mycity.mysticdrains.org
```
6. Create a CNAME [DNS record in squarespace](https://support.squarespace.com/hc/en-us/articles/360002101888) pointing to the `DNS Target` target listed by `heroku domains`. 
5. Load drain data (see below)
6. Configure report recipients (see below)

# Load or Update drain data

Drain data is stored in raw form in CSV files. These files are the source of truth for the drains in the system.

For new cities or when updating an existing city, load drain data from the csv configured in the city configuration file:

`heroku run rake data:load_drains cities=everett`

Or load multiple or all:

`heroku run rake data:load_drains cities=all`

`heroku run rake data:load_drains cities="everett cambridge"`

**Note**: For all commands, you must add `write=true` to actually write changes to the database: `heroku run rake data:load_drains cities=everett write=true`.

Review the output of a dry run before writing. 

The loader matches input rows to existing records by location and id. If no ID is provided in the input data, a unique, random id is created. Two rows match if they have the same ID or are within 1 foot of each other.

The loader updates drains with exactly one match, copying everything but the name. It refuses to update any inputs with multiple matches. Finally, any existing drains that are not matched to an input are deleted.

If any input rows match any other input rows, the loader prints a warning and selects the first one.

# Configure report recipients

Reports are sent to administrators for each city. The emails are stored in the database and configured using a json snippet. For new cities or to update the emails:

```json
// report-config.json
[
  {
    "city": "everett",
    "emails": ["me@example.com", "me2@example.com"]
  },
  {
    "city": "cambridge",
    "emails": ["me3@example.com"]
  }
]
```

`heroku run rake mail:configure_reports config="$(cat report-config.json)"`

# Send usage report

Usage reports are automatically sent monthly using [Herokue Scheduler](https://devcenter.heroku.com/articles/scheduler). 

To manually send reports to some or all cities:

`heroku run rake mail:send_reports cities="everett cambridge"`

`heroku run rake mail:send_reports cities=all`

