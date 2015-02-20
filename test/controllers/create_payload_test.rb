require "./test/test_helper"

class CreatePayloadTest < MiniTest::Test
  include Rack::Test::Methods
	attr_reader :identifier, :payload_data, :payload, :source

  def setup
  	@identifier =  { identifier: "jumpstartlab",
  									 root_url: "http://jumpstartlab.com" }

  	@payload_data =  'payload={"url":"http://jumpstartlab.com/blog","requestedAt":"2013-02-16 21:38:28 -0700","respondedIn":37,"referredBy":"http://jumpstartlab.com","requestType":"GET","parameters":[],"eventName": "socialLogin","userAgent":"Mozilla/5.0 (Macintosh%3B Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1309.0 Safari/537.17","resolutionWidth":"1920","resolutionHeight":"1280","ip":"63.29.38.211"}'
  end

  def app
    TrafficSpy::Server
  end

  def teardown
    DatabaseCleaner.clean
  end

  def register_app
    post "/sources", identifier
  end

  def test_create_payload_has_correct_parameters
    register_app
  	assert_equal 200, last_response.status

  	post "/sources/jumpstartlab/data", payload_data
  	assert_equal 200, last_response.status
  	assert_equal Payload.where(source_id: 1), Source.find(1).payloads
  end

  def test_request_with_missing_payload_returns_error

    post "/sources/jumpstartlab/data", '" " http://localhost:9393/sources/jumpstartlab/data'
    assert_equal 400, last_response.status
    assert last_response.body.include?("missing payload")
  end

  def test_duplicated_request_returns_error
    skip
    register_app
    post "/sources/jumpstartlab/data", payload_data
    assert_equal 200, last_response.status
    post "/sources/jumpstartlab/data", payload_data
    assert_equal 403, last_response.status
    assert_equal "duplicate request", last_response.body
  end

  def test_unregistered_application_cannot_request_data
    post "/sources/kyrasapp/data", payload_data
    assert_equal 403, last_response.status
    assert "not registered application", last_response.body.include?("missing payload")
  end

 end
