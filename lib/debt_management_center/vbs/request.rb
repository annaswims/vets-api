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
              "additionalComments" => "The house stood on a slight rise just on the edge of the village. It stood on its own and looked out over a broad spread of West Country farmland. Not a remarkable house by any means—it was about thirty years old, squattish, squarish, made of brick, and had four windows set in the front of a size and proportion which more or less exactly failed to please the eye. The only person for whom the house was in any way special was Arthur Dent, and that was only because it happened to be the one he lived in. He had lived in it for about three years, ever since he had moved out of London because it made him nervous and irritable. He was about thirty as well, tall, dark-haired and never quite at ease with himself. The thing that used to worry him most was the fact that people always used to ask him what he was looking so worried about. He worked in local radio which he always used to tell his friends was a lot more interesting than they probably thought. It was, too—most of his friends worked in advertising.On Wednesday night it had rained very heavily, the lane was wet and muddy, but the Thursday morning sun was bright and clear as it shone on Arthur Dent’s house for what was to be the last time." 
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
