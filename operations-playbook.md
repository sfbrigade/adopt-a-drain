# Playbook

## Deployment

### Environment configuration

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

### Deploying

`git push heroku master`

### Database

Initially, set up the db schema:

`heroku run rake db:schema:load`

Then, whenever migrations are added, load them:

`heroku run rake db:migrate`

## Set Up a New City

1. Add a configuration file under `config/cities`. The name of the file is used as the id of the city.
2. Add drain data under `config/cities/data` and reference it in the city config.
3. Load drain data (see below)
4. Configure report recipients (see below)

### Update drain data

For new cities or when updating an existing city, load drain data from the csv configured in the city configuration file:

`heroku run rake data:load_drains cities=everett`

Or load multiple or all:

`heroku run rake data:load_drains cities=all`

`heroku run rake data:load_drains cities="everett cambridge"`

### Configure report recipients

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

### Send usage report

Usage reports are automatically sent monthly using [Herokue Scheduler](https://devcenter.heroku.com/articles/scheduler). 

To manually send reports to some or all cities:

`heroku run rake mail:send_reports cities="everett cambridge"`

`heroku run rake mail:send_reports cities=all`

