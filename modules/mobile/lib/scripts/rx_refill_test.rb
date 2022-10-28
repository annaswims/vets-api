# frozen_string_literal: true

require 'faraday'
require 'json'
require 'pry'
require 'async'

class RxRefillTest
  def initialize(rx_id, access_token)
    @access_token = access_token
    @rx_id = rx_id
  end

  def run
    spam_index
  end

  private

  def spam_index
    Async do |task|
      40.times do |i|
        test_number = i + 1
        puts "Synchronously testing #{test_number}"
          task.async do
            output_index(test_number)
          end
        end
        # sleep(0.25)
      end
    end
  end

  def output_index(test_number)
    puts "Asynchronously testing #{test_number}"
    puts "STARTING TEST AT: "
    pp Time.now

    response = get_prescriptions_index
    parsed = JSON.parse(response.body)
    match = parsed['data'].find { |rx| rx['id'] == @rx_id }
    puts
    puts "=== TEST NUMBER #{test_number} ==="
    pp Time.now
    puts '=== RESULT ==='
    puts match
    puts
  end

  # def update_refill
  #   path = "/v0/health/rx/prescriptions/#{@rx_id}/refill"
  #   connection.put(path)
  # end

  def get_prescriptions_index
    path = 'mobile/v0/health/rx/prescriptions'
    connection.get(path)
  end

  def connection
    Faraday.new(
      url: 'https://staging-api.va.gov',
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@access_token}",
        'X-Key-Inflection' => 'camel'
      }
    )
  end
end

if __FILE__ == $PROGRAM_NAME
  rx_id = ARGV[0]
  access_token = ARGV[1]
  script = RxRefillTest.new(rx_id, access_token)
  script.run
end
