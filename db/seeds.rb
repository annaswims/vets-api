# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# form data was derived from #create! errors and the form in spec/models/saved_claim/pension_spec.rb
form = {
  privacyAgreementAccepted: true,
  veteranFullName: {
    first: 'Test',
    last: 'User'
  },
  veteranDateOfBirth: '1989-12-13',
  veteranSocialSecurityNumber: '111223333',
  claimantAddress: {
    country: 'USA',
    state: 'CA',
    postalCode: '90210',
    street: '123 Main St',
    city: 'Anytown'
  }
}.to_json

5000.times do
  SavedClaim::Burial.create!(:form_id => '21P-530', :guid =>SecureRandom.uuid, :type => SavedClaim::Burial.to_s, :form => form)
end
