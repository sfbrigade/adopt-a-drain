# frozen_string_literal: true

def round_off(time, seconds = 60)
  Time.at((time.to_f / seconds).round * seconds).utc
end

class AdoptionsMailer < ApplicationMailer
  # rubocop:disable Metrics/AbcSize
  def usage_report
    @current_city = params[:city]
    @city = City.where(name: @current_city).first!
    @config = CityHelper.config(@current_city)

    compute_stats
    attach_files

    mail(
      from: "Adopt a Drain #{@config.city.name} <noreply@mysticdrains.org>",
      to: @city.export_recipient_emails,
      subject: "Usage Report for Adopt a Drain #{@config.city.name}",
      reply_to: @config.org.email,
    )

    @city.update(
      last_export_time: @export_time, last_adoption_count: @adoption_count, last_user_count: @user_count,
    )
  end
  # rubocop:enable Metrics/AbcSize

  def days_since_last_report
    d = (@export_time - @city.last_export_time).to_f
    t = 1.day.to_f
    (d / t).round
  end
  helper_method :days_since_last_report

  def compute_stats
    @export_time = Time.zone.now
    @user_count = users.count
    @adoption_count = adopted_drains.count
  end

  def users
    User.where(city_domain: @city.name)
  end

  def adopted_drains
    Thing.where(city_domain: @city.name).where.not(user_id: nil)
  end

  def attach_files
    date = @export_time.strftime('%m-%d-%Y')
    attachments["signups-#{date}.csv"] = signups_csv
    attachments["adopted-drains-#{date}.csv"] = adopted_drains_csv
  end

  def adopted_drains_csv
    CSV.generate(
      write_headers: true,
      headers: %w[id email_address lat lng],
    ) do |csv|
      adopted_drains.each do |t|
        csv << [t.city_id, t.user.email, t.lat, t.lng]
      end
    end
  end

  def signups_csv
    CSV.generate(
      write_headers: true,
      headers: %w[first_name last_name email joined_at],
    ) do |csv|
      users.each do |u|
        csv << [u.first_name, u.last_name, u.email, u.created_at]
      end
    end
  end
end
