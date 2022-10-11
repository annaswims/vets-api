# frozen_string_literal: true

module DebtManagementCenter
  module VBS
    ##
    # An object responsible for making HTTP calls to the VBS service that relate to DMC
    #
    # @!attribute settings
    #   @return [Config::Options]
    # @!attribute host
    #   @return (see Config::Options#host)
    # @!attribute service_name
    #   @return (see Config::Options#service_name)
    # @!attribute url
    #   @return (see Config::Options#url)
    class Request
      extend Forwardable
      include Common::Client::Concerns::Monitoring

      STATSD_KEY_PREFIX = 'api.vbs.financial_status_report.request'

      attr_reader :settings

      def_delegators :settings, :base_path, :host, :service_name, :url

      ##
      # Builds a DebtManagementCenter::VBS::Request instance
      #
      # @return [DebtManagementCenter::VBS::Request] an instance of this class
      def self.build
        new
      end

      def initialize
        @settings = Settings.mcp.vbs_v2
      end

      ##
      # Make a HTTP POST call to the VBS service in order to submit VHA FSR
      #
      # @param path [String]
      # @param params [Hash]
      #
      # @return [Faraday::Response]
      #
      def post(path, params)
        with_monitoring do
          connection.post(path) do |req|
            req.body = params
          end
        end
      end

      ##
      # Create a connection object that managers the attributes
      # and the middleware stack for making our HTTP requests to VBS
      #
      # @return [Faraday::Connection]
      #
      def connection
        Faraday.new(url: url, headers: headers) do |conn|
          conn.request :json
          conn.use :breakers
          conn.use Faraday::Response::RaiseError
          conn.response :raise_error, error_prefix: service_name
          conn.response :json
          conn.response :betamocks if mock_enabled?
          conn.adapter Faraday.default_adapter
        end
      end

      ##
      # HTTP request headers for the VBS API
      #
      # @return [Hash]
      #
      def headers
        {
          'Host' => host,
          'Content-Type' => 'application/json',
          'apiKey' => settings.api_key
        }
      end

      def generate_payload
      d = {
          "personalIdentification" => {
              "ssn" => Faker::Number.number(digits: 4).to_s,
              "fileNumber" => Faker::Number.number(digits: 10).to_s,
              "fsrReason" => Faker::Lorem.word
          },
          "personalData" => {
              "veteranFullName" => {
                  "first" => Faker::Name.first_name,
                  "middle" => Faker::Name.initials(number: 1),
                  "last" => Faker::Name.last_name
              },
              "address" => {
                  "addresslineOne" => Faker::Address.street_address,
                  "addresslineTwo" => Faker::Address.secondary_address,
                  "addresslineThree" => '',
                  "city" => Faker::Address.city,
                  "stateOrProvince" => Faker::Address.state_abbr,
                  "zipOrPostalCode" => Faker::Address.zip,
                  "countryName" => Faker::Address.country
              },
              "telephoneNumber" => Faker::PhoneNumber.cell_phone,
              "emailAddress" => Faker::Internet.email,
              "dateOfBirth" => "#{Faker::Number.between(from: 1, to: 12)}/#{Faker::Number.between(from: 1, to: 28)}/#{Faker::Number.between(from: 1930, to: 2004)}",
              "married" => true,
              "spouseFullName" => {
                  "first" => Faker::Name.first_name,
                  "middle" => Faker::Name.initials(number: 1),
                  "last" => Faker::Name.last_name
              },
              "agesOfOtherDependents" => [
                  Faker::Number.between(from: 1, to: 17).to_s,
                  Faker::Number.between(from: 1, to: 17).to_s
              ],
              "employmentHistory" => [
                  {
                      "veteranOrSpouse" => "VETERAN",
                      "occupationName" => Faker::Job.title,
                      "from" => "#{Faker::Number.between(from: 1, to: 12)}/#{Faker::Number.between(from: 2015, to: 2021)}",
                      "to" => "",
                      "present" => true,
                      "employerName" => Faker::Company.name,
                      "employerAddress" => {
                        "addresslineOne" => Faker::Address.street_address,
                        "addresslineTwo" => Faker::Address.secondary_address,
                        "addresslineThree" => '',
                        "city" => Faker::Address.city,
                        "stateOrProvince" => Faker::Address.state_abbr,
                        "zipOrPostalCode" => Faker::Address.zip,
                        "countryName" => Faker::Address.country
                      }
                  },
                  {
                      "veteranOrSpouse" => "VETERAN",
                      "occupationName" => Faker::Job.title,
                      "from" => "#{Faker::Number.between(from: 1, to: 12)}/#{Faker::Number.between(from: 2000, to: 2014)}",
                      "to" => "#{Faker::Number.between(from: 1, to: 12)}/2015",
                      "present" => false,
                      "employerName" => Faker::Company.name,
                      "employerAddress" => {
                        "addresslineOne" => Faker::Address.street_address,
                        "addresslineTwo" => Faker::Address.secondary_address,
                        "addresslineThree" => '',
                        "city" => Faker::Address.city,
                        "stateOrProvince" => Faker::Address.state_abbr,
                        "zipOrPostalCode" => Faker::Address.zip,
                        "countryName" => Faker::Address.country
                      }
                  },
                  {
                      "veteranOrSpouse" => "SPOUSE",
                      "occupationName" => Faker::Job.title,
                      "from" => "#{Faker::Number.between(from: 1, to: 12)}/#{Faker::Number.between(from: 2015, to: 2021)}",
                      "to" => "",
                      "present" => true,
                      "employerName" => Faker::Company.name,
                      "employerAddress" => {
                        "addresslineOne" => Faker::Address.street_address,
                        "addresslineTwo" => Faker::Address.secondary_address,
                        "addresslineThree" => '',
                        "city" => Faker::Address.city,
                        "stateOrProvince" => Faker::Address.state_abbr,
                        "zipOrPostalCode" => Faker::Address.zip,
                        "countryName" => Faker::Address.country
                      }
                  }
              ]
          },
          "income" => [
              {
                  "veteranOrSpouse" => "VETERAN",
                  "monthlyGrossSalary" => Faker::Number.number(digits: 4).to_s,
                  "deductions" => {
                      "taxes" => Faker::Number.number(digits: 3).to_s,
                      "retirement" => Faker::Number.number(digits: 3).to_s,
                      "socialSecurity" => Faker::Number.number(digits: 3).to_s,
                      "otherDeductions" => {
                          "name" => Faker::Lorem.sentence,
                          "amount" => Faker::Number.number(digits: 3).to_s
                      }
                  },
                  "totalDeductions" => Faker::Number.number(digits: 3).to_s,
                  "netTakeHomePay" => Faker::Number.number(digits: 5).to_s,
                  "otherIncome" => {
                      "name" => Faker::Lorem.sentence,
                      "amount" =>Faker::Number.number(digits: 3).to_s
                  },
                  "totalMonthlyNetIncome" => Faker::Number.number(digits: 4).to_s
              },
              {
                  "veteranOrSpouse" => "SPOUSE",
                  "monthlyGrossSalary" => Faker::Number.number(digits: 4).to_s,
                  "deductions" => {
                      "taxes" => Faker::Number.number(digits: 3).to_s,
                      "retirement" => Faker::Number.number(digits: 3).to_s,
                      "socialSecurity" => Faker::Number.number(digits: 3).to_s,
                      "otherDeductions" => {
                          "name" => Faker::Lorem.sentence,
                          "amount" => Faker::Number.number(digits: 3).to_s
                      }
                  },
                  "totalDeductions" => Faker::Number.number(digits: 3).to_s,
                  "netTakeHomePay" => Faker::Number.number(digits: 5).to_s,
                  "otherIncome" => {
                      "name" => Faker::Lorem.sentence,
                      "amount" =>Faker::Number.number(digits: 3).to_s
                  },
                  "totalMonthlyNetIncome" => Faker::Number.number(digits: 4).to_s
              }
          ],
          "expenses" => {
              "rentOrMortgage" => Faker::Number.number(digits: 3).to_s,
              "food" => Faker::Number.number(digits: 3).to_s,
              "utilities" => Faker::Number.number(digits: 3).to_s,
              "otherLivingExpenses" => {
                  "name" => Faker::Lorem.sentence,
                  "amount" => Faker::Number.number(digits: 3).to_s
              },
              "expensesInstallmentContractsAndOtherDebts" => Faker::Number.number(digits: 3).to_s,
              "totalMonthlyExpenses" => Faker::Number.number(digits: 4).to_s
          },
          "discretionaryIncome" => {
              "netMonthlyIncomeLessExpenses" => Faker::Number.number(digits: 4).to_s,
              "amountCanBePaidTowardDebt" => Faker::Number.number(digits: 3).to_s
          },
          "assets" => {
              "cashInBank" => Faker::Number.number(digits: 5).to_s,
              "cashOnHand" => Faker::Number.number(digits: 3).to_s,
              "automobiles" => [
                  {
                      "make" => Faker::Vehicle.make,
                      "model" => Faker::Vehicle.model,
                      "year" => Faker::Number.between(from: 1960, to: 2020).to_s,
                      "resaleValue" => Faker::Number.number(digits: 4).to_s
                  },
                  {

                  }
              ],
              "trailersBoatsCampers" => Faker::Number.number(digits: 3).to_s,
              "usSavingsBonds" => Faker::Number.number(digits: 3).to_s,
              "stocksAndOtherBonds" => Faker::Number.number(digits: 4).to_s,
              "realEstateOwned" => Faker::Number.number(digits: 6).to_s,
              "otherAssets" => [
                  {
                      "name" => Faker::Lorem.word,
                      "amount" => Faker::Number.number(digits: 3).to_s
                  }
              ],
              "totalAssets" => Faker::Number.number(digits: 6).to_s
          },
          "installmentContractsAndOtherDebts" => [
              {
                  "creditorName" => Faker::Bank.name,
                  "creditorAddress" => {
                    "addresslineOne" => Faker::Address.street_address,
                    "addresslineTwo" => Faker::Address.secondary_address,
                    "addresslineThree" => '',
                    "city" => Faker::Address.city,
                    "stateOrProvince" => Faker::Address.state_abbr,
                    "zipOrPostalCode" => Faker::Address.zip,
                    "countryName" => Faker::Address.country
                  },
                  "dateStarted" => "#{Faker::Number.between(from: 1, to: 12)}/#{Faker::Number.between(from: 1, to: 28)}/#{Faker::Number.between(from: 1990, to: 2022)}",
                  "purpose" => Faker::Lorem.sentence,
                  "originalAmount" => Faker::Number.number(digits: 5).to_s,
                  "unpaidBalance" => Faker::Number.number(digits: 4).to_s,
                  "amountDueMonthly" => Faker::Number.number(digits: 3).to_s,
                  "amountPastDue" => Faker::Number.number(digits: 2).to_s
              }
          ],
          "totalOfInstallmentContractsAndOtherDebts" => {
            "originalAmount" => Faker::Number.number(digits: 5).to_s,
            "unpaidBalance" => Faker::Number.number(digits: 4).to_s,
            "amountDueMonthly" => Faker::Number.number(digits: 3).to_s,
            "amountPastDue" => Faker::Number.number(digits: 2).to_s
          },
          "additionalData" => {
              "bankruptcy" => {
                  "hasBeenAdjudicatedBankrupt" => true,
                  "dateDischarged" => "#{Faker::Number.between(from: 1, to: 12)}/#{Faker::Number.between(from: 1, to: 28)}/#{Faker::Number.between(from: 1990, to: 2022)}",
                  "courtLocation" => Faker::Address.city,
                  "docketNumber" => Faker::Number.number(digits: 8).to_s
              },
              "additionalComments" => Faker::Lorem.paragraph + "\nIndividual Expense Amount: Groceries ($100)\nHaircut ($25)"
          },
          "applicantCertifications" => {
              "veteranSignature" => Faker::Name.name,
              "veteranDateSigned" => "06/#{Faker::Number.between(from: 1, to: 28)}/2022"
          }
      }

      File.open('lib/debt_management_center/vbs/temp.json', 'w') do |f|
        f.write(d.to_json)
      end

      d
      end

      ##
      # Betamocks enabled status from settings
      #
      # @return [Boolean]
      #
      def mock_enabled?
        settings.mock || false
      end
    end
  end
end
