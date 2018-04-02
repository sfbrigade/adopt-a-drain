# frozen_string_literal: true

# class for rectifying adoptions of invalid data

class AdoptionMover
  class << self
    # Move adoptions deleted later than `from` to close by unadopted things
    # within `maximum_movement_in_feet` away
    #
    # Returns a hash of {to_id: from_id}
    def move_close_deleted_adoptions(from, maximum_movement_in_feet)
      moved_adoptions = {}

      Thing.transaction do
        records = ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
          WITH
            deleted_adopted_things AS (
              SELECT *
              FROM things
              WHERE
                user_id IS NOT NULL
                -- only recently deleted things
                AND (deleted_at > #{ActiveRecord::Base.sanitize(from)})
            )
          SELECT
            deleted_adopted_things.id AS deleted_adopted_thing_id,
            closest_unadopted_thing.id AS closest_unadopted_thing_id
          FROM
            deleted_adopted_things
          LEFT JOIN LATERAL (
              SELECT *,
                  -- earth_distance returns meters
                  earth_distance(
                    ll_to_earth(deleted_adopted_things.lat, deleted_adopted_things.lng),
                    ll_to_earth(unadopted_things.lat, unadopted_things.lng)
                  ) * 3.28 as distance_in_feet
              FROM things AS unadopted_things
              WHERE deleted_at IS NULL AND user_id IS NULL
              ORDER BY distance_in_feet
              LIMIT 1
            ) AS closest_unadopted_thing ON 1=1
          WHERE distance_in_feet < #{ActiveRecord::Base.sanitize(maximum_movement_in_feet)}
          ORDER BY distance_in_feet
          ;
SQL

        records.each do |record|
          deleted_adopted_thing = Thing.unscoped.find(record['deleted_adopted_thing_id'])
          closeby_unadopted_thing = Thing.find(record['closest_unadopted_thing_id'])

          closeby_unadopted_thing.update!(
            user_id: deleted_adopted_thing.user_id,
            adopted_name: deleted_adopted_thing.adopted_name,
          )
          deleted_adopted_thing.update!(user_id: nil)

          moved_adoptions[deleted_adopted_thing.id] = closeby_unadopted_thing.id
        end
      end

      moved_adoptions
    end
  end
end
