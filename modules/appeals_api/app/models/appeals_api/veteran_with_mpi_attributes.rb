# frozen_string_literal: true

# Subclass of AppealsApi::Appellant, specifically intended for
# calling MPI:Service's find_profile method with address attributes
# in lieu of an ssn.
module AppealsApi
  class VeteranWithMPIAttributes < Appellant
    def address
      form_data['address'] || {}
    end

    def birth_date
      auth_headers['X-VA-Birth-Date']
    end

    # Required by MPI when validating in message_user_attributes
    # (See lib/mpi/service.rb)
    def valid?
      true
    end

    # The following attributes we don't take in for NOD,
    # but they are required for MPI
    def gender
      nil
    end

    def authn_context
      nil
    end

    def uuid
      nil
    end
  end
end
