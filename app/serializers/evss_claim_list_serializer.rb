# frozen_string_literal: true

# BEGIN lighthouse_migration
class EVSSClaimListSerializer < EVSSClaimBaseSerializer
  def phase
    phase_from_keys 'status'
  end

  private

  def object_data
    object.list_data
  end
end
# END lighthouse_migration
