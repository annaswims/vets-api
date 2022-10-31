# frozen_string_literal: true

require 'faraday'
require 'json'
require 'pry'

class RxRefillTest
  def initialize(rx_id, access_token)
    @access_token = access_token
    @rx_id = rx_id
  end

  def run
    output_index('BASELINE')
    # update_refill
    spam_index
  end

  private

  def spam_index
    5.times do |i|
      test_number = i + 1
      output_index(test_number)
    end
  end

  def output_index(test_number)
    puts "=== START TESTING #{test_number} ==="
    start_time = Time.now
    puts

    response = get_prescriptions_index
    parsed = JSON.parse(response.body)
    match = parsed['data'].find { |rx| rx['id'] == @rx_id }

    duration = Time.now - start_time
    puts "REQUEST TOOK: #{duration} seconds"
    puts '=== RESULT ==='
    puts match
    puts
    puts "=== FINISHED TESTING #{test_number} ==="
    puts
    puts '---------------------------------------'
    puts
  rescue => e
    puts e
  end

  # def update_refill
  #   path = "mobile/v0/health/rx/prescriptions/#{@rx_id}/refill"
  #   response = connection.put(path)
  #   puts "=== UPDATED RX #{@rx_id} ==="
  # end

  def get_prescriptions_index
    path = 'mobile/v0/health/rx/prescriptions'
    connection.get(path)
  end

  def connection
    @connection ||= Faraday.new(
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
