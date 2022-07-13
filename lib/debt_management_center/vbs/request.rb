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
            req.body = Oj.dump(params)
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
          'x-api-key' => settings.api_key
        }
      end

      def generate_payload
        {
          "personalIdentification" => {
              "ssn" => Faker::Number.number(digits: 10),
              "fileNumber" => Faker::Number.number(digits: 10),
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
                  Faker::Number.between(from: 1, to: 17),
                  Faker::Number.between(from: 1, to: 17)
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
                  "monthlyGrossSalary" => Faker::Number.number(digits: 4),
                  "deductions" => {
                      "taxes" => Faker::Number.number(digits: 3),
                      "retirement" => Faker::Number.number(digits: 3),
                      "socialSecurity" => Faker::Number.number(digits: 3),
                      "otherDeductions" => {
                          "name" => Faker::Lorem.sentence,
                          "amount" => Faker::Number.number(digits: 3)
                      }
                  },
                  "totalDeductions" => Faker::Number.number(digits: 3),
                  "netTakeHomePay" => Faker::Number.number(digits: 5),
                  "otherIncome" => {
                      "name" => Faker::Lorem.sentence,
                      "amount" =>Faker::Number.number(digits: 3)
                  },
                  "totalMonthlyNetIncome" => Faker::Number.number(digits: 4)
              },
              {
                  "veteranOrSpouse" => "SPOUSE",
                  "monthlyGrossSalary" => Faker::Number.number(digits: 4),
                  "deductions" => {
                      "taxes" => Faker::Number.number(digits: 3),
                      "retirement" => Faker::Number.number(digits: 3),
                      "socialSecurity" => Faker::Number.number(digits: 3),
                      "otherDeductions" => {
                          "name" => Faker::Lorem.sentence,
                          "amount" => Faker::Number.number(digits: 3)
                      }
                  },
                  "totalDeductions" => Faker::Number.number(digits: 3),
                  "netTakeHomePay" => Faker::Number.number(digits: 5),
                  "otherIncome" => {
                      "name" => Faker::Lorem.sentence,
                      "amount" =>Faker::Number.number(digits: 3)
                  },
                  "totalMonthlyNetIncome" => Faker::Number.number(digits: 4)
              }
          ],
          "expenses" => {
              "rentOrMortgage" => Faker::Number.number(digits: 3),
              "food" => Faker::Number.number(digits: 3),
              "utilities" => Faker::Number.number(digits: 3),
              "otherLivingExpenses" => {
                  "name" => Faker::Lorem.sentence,
                  "amount" => Faker::Number.number(digits: 3)
              },
              "expensesInstallmentContractsAndOtherDebts" => Faker::Number.number(digits: 3),
              "totalMonthlyExpenses" => Faker::Number.number(digits: 4)
          },
          "discretionaryIncome" => {
              "netMonthlyIncomeLessExpenses" => Faker::Number.number(digits: 4),
              "amountCanBePaidTowardDebt" => Faker::Number.number(digits: 3)
          },
          "assets" => {
              "cashInBank" => Faker::Number.number(digits: 5),
              "cashOnHand" => Faker::Number.number(digits: 3),
              "automobiles" => [
                  {
                      "make" => Faker::Vehicle.make,
                      "model" => Faker::Vehicle.model,
                      "year" => Faker::Number.between(from: 1960, to: 2020),
                      "resaleValue" => Faker::Number.number(digits: 4)
                  },
                  {

                  }
              ],
              "trailersBoatsCampers" => Faker::Number.number(digits: 3),
              "usSavingsBonds" => Faker::Number.number(digits: 3),
              "stocksAndOtherBonds" => Faker::Number.number(digits: 4),
              "realEstateOwned" => Faker::Number.number(digits: 6),
              "otherAssets" => [
                  {
                      "name" => Faker::Lorem.word,
                      "amount" => Faker::Number.number(digits: 3)
                  }
              ],
              "totalAssets" => Faker::Number.number(digits: 6)
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
                  "originalAmount" => Faker::Number.number(digits: 5),
                  "unpaidBalance" => Faker::Number.number(digits: 4),
                  "amountDueMonthly" => Faker::Number.number(digits: 3),
                  "amountPastDue" => Faker::Number.number(digits: 2)
              }
          ],
          "totalOfInstallmentContractsAndOtherDebts" => {
            "originalAmount" => Faker::Number.number(digits: 5),
            "unpaidBalance" => Faker::Number.number(digits: 4),
            "amountDueMonthly" => Faker::Number.number(digits: 3),
            "amountPastDue" => Faker::Number.number(digits: 2)
          },
          "additionalData" => {
              "bankruptcy" => {
                  "hasBeenAdjudicatedBankrupt" => true,
                  "dateDischarged" => "#{Faker::Number.between(from: 1, to: 12)}/#{Faker::Number.between(from: 1, to: 28)}/#{Faker::Number.between(from: 1990, to: 2022)}",
                  "courtLocation" => Faker::Address.city,
                  "docketNumber" => Faker::Number.number(digits: 8)
              },
              "additionalComments" => Faker::Lorem.paragraph
          },
          "applicantCertifications" => {
              "veteranSignature" => Faker::Name.name,
              "veteranDateSigned" => "06/#{Faker::Number.between(from: 1, to: 28)}/2022"
          }
      }
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
