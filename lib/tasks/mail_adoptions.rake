# frozen_string_literal: true

# from Savannah implementation
# run with:
# docker compose run web bundle exec rake mail:configure_reports config="$(cat report-config.json)"
# docker compose run web bundle exec rake mail:send_reports cities=everett period_in_days=0
# docker compose run web bundle exec rake mail:send_system_report period_in_days=0
# or
# heroku run rake mail:send_reports cities="everett cambridge" period_in_days=0
# heroku run rake mail:send_reports cities=all period_in_days=0
# heroku run rake mail:send_system_report period_in_days=0
#
# See DevOps.md

def filter_reports(cities)
  period_in_days = ENV.fetch('period_in_days', 30).to_i
  now = Time.zone.now
  cities.filter do |c|
    c = City.where(name: c).first
    if c.nil? || c.export_recipient_emails.empty?
      false
    else
      now > c.last_export_time + period_in_days.days
    end
  end
end

namespace 'mail' do
  task send_reports: :environment do
    cities = ENV.fetch('cities')
    cities = if cities == 'all'
               CityHelper.city_names
             else
               cities.split(' ').map { |c| CityHelper.check(c) }
             end
    cities = filter_reports(cities)

    puts "Processing #{cities}"

    cities.each do |city|
      puts "Sending report for #{city}"
      AdoptionsMailer.with(city: city).usage_report.deliver_now
    end
  end

  task send_system_report: :environment do
    should_send = filter_reports(['system']).first.present?
    if should_send
      puts 'Sending system report'
      AdoptionsMailer.system_usage_report.deliver_now
    end
  end

  task configure_reports: :environment do
    config = JSON.parse ENV.fetch('config')

    puts "Processing #{config}"

    config.each do |c|
      name = c.fetch('city')
      name = name == 'system' ? name : CityHelper.check(name)
      emails = c.fetch('emails')

      puts "Configuring #{name}"

      city = City.find_or_initialize_by(name: name)
      city.update(export_recipient_emails: emails)
    end
  end
end
