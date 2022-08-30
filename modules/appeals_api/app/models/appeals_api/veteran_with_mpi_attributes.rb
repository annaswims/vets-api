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

    # Required by MPI when validating in message_user_attributes.
    # (See lib/mpi/service.rb)
    def valid?
      true
    end

    # We don't take the following attributes in for NOD,
    # but they are required for MPI.
    def gender
      nil
    end

    def authn_context
      nil
    end

    def uuid
      nil
    end

    # The follow methods get checked for in create_profile_message,
    # but aren't need for our purposes.
    # (See lib/mpi/service.rb)
    def mhv_icn
      nil
    end

    def edipi
      nil
    end

    def logingov_uuid
      nil
    end

    def idme_uuid
      nil
    end

    def middle_name
      nil
    end
  end
end
