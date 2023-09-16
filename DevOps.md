# Developer Operations Playbook

How to run and maintain the site.

# Development

## Setup

- Install the [heroku command line](https://devcenter.heroku.com/articles/heroku-cli)
- Create a Heroku account and get added to the [Adopt-a-Drain project](https://dashboard.heroku.com/apps/adopt-a-drain-mrwa)
- Set up your Heroku command line and connect it to the project:
  ```bash
  # Log in to heroku
  heroku login
  # Add the heroku remote to your git config. This will allow you to push to heroku and also configures sets the project for the heroku command line.
  heroku git:remote -a adopt-a-drain-mrwa
  # Get the latest code from heroku
  git fetch heroku
  # Confirm that the heroku remote and app is set up correctly.
  heroku apps:info
  ```
- Get the Google Maps and optionally mailserver credentials from the heroku project for local development by running `heroku config`.
- Create a `.env` file in the repo root directory with the following contents for local development:
  ```sh
  PORT=3000
  DB_HOST=db
  DB_PASSWORD=postgres
  DB_USER=postgres
  SECRET_KEY_BASE=secret

  GOOGLE_MAPS_JAVASCRIPT_API_KEY=<from heroku config>
  GOOGLE_GEOCODER_API_KEY=<from heroku config>
  GOOGLE_MAPS_KEY=<from heroku config>

  # Optional
  # MAILSERVER_HOST=<from heroku config>
  # MAILSERVER_DOMAIN=<from heroku config>
  # MAILSERVER_USERNAME=<from heroku config>
  # MAILSERVER_PASSWORD=<from heroku config>
  ```

## Usage

The first time you run the app, or whenever you want to start fresh, run these commands. This will start the app in the background and tail the logs:

```bash

# Tears everything down, creates and sets up the database.
docker compose down -v
docker compose up db -d
docker compose run web bundle exec rake db:create
docker compose run web bundle exec rake db:schema:load
docker compose run web bundle exec rake db:migrate
docker compose up web -d
docker compose logs -f

# Loads in city data for everett
docker compose exec web bundle exec rake data:load_drains cities=everett write=true

# Or, to load all city data
# docker compose exec web bundle exec rake data:load_drains cities=all write=true

```

Now you can access the site at http://localhost:3000. This loads the default city, everett. To access a different city, use the city name as the subdomain, e.g. http://somerville.localhost:3000. Any city with a file under `config/cities` can be accessed this way.

To stop the app, run `docker compose down`. To start it again, run `docker compose up`. This will run the app in the foregound and stop it when you press `ctrl-c`. The database will be persisted between runs. To stop the app and remove the database, run `docker compose down -v`.

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

The site is deployed by pushing to the heroku remote. Ensure everything is committed to `master` and run:

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

Reports are sent to administrators for each city, and MyRWA at a system level. The emails are stored in the database and configured using a json snippet. For new cities or to update the emails:

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
  // Configure the system report with the `system` city name
  {
    "city": "system",
    "emails": ["me4@example.com"]
  }
]
```

Note that the system report is configured with the `system` city name. Then, run this command to set the emails in the file. Only cities listed in the file will be affected:

`heroku run rake mail:configure_reports config="$(cat report-config.json)"`

# Send usage report

Usage reports are automatically sent monthly using [Herokue Scheduler](https://devcenter.heroku.com/articles/scheduler). 

To manually send reports to some or all cities:

`heroku run rake mail:send_reports cities="everett cambridge" period_in_days=0`

`heroku run rake mail:send_reports cities=all period_in_days=0`

To manually send the system usage report:

`heroku run rake mail:send_system_report period_in_days=0`
