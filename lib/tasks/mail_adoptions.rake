# frozen_string_literal: true

# from Savannah implementation
# run with:
# docker-compose run --rm web bundle exec rake data:load_drains[everett]
# or
# heroku rake data:load_drains[everett]

namespace 'mail' do
  # rake mail:send_reports cities="everett cambridge"
  # rake mail:send_reports cities="all"
  task send_reports: :environment do
    cities = ENV.fetch('cities')
    cities = if cities == 'all'
               CityHelper.city_names
             else
               cities.split(' ').map { |c| CityHelper.check(c) }
             end
    cities = cities.filter { |c| City.where(name: c).any? }

    puts "Processing #{cities}"

    cities.each do |city|
      puts "Sending report for #{city}"
      AdoptionsMailer.with(city: city).usage_report.deliver_now
    end
  end

  task send_system_report: :environment do
    recipients = ENV.fetch('recipients').split(' ')
    puts "Sending system report to #{recipients}"
    AdoptionsMailer.with(recipients: recipients).system_usage_report.deliver_now
  end

  # rake mail:configure_reports config='[{"city": "everett", "emails": ["me@example.com", "me2@example.com"]}]'
  task configure_reports: :environment do
    config = JSON.parse ENV.fetch('config')

    puts "Processing #{config}"

    config.each do |c|
      name = CityHelper.check(c.fetch('city'))
      emails = c.fetch('emails')

      puts "Configuring #{name}"

      city = City.find_or_initialize_by(name: name)
      city.update(export_recipient_emails: emails)
    end
  end
end
