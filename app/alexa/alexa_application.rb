require 'json'

# helper to make nested hashes accessible via method calls
def smart_hash(h)
  h = Hash[h.map{|k,v| [k, v.is_a?(Hash) ? smart_hash(v) : v]}]
  h.instance_eval do
    def method_missing(name, *args, &block)
      self[name.to_s]
    end
  end
  h
end

# AlexaApplication helps parse Alexa Skills SDK requests, dispatch response
class AlexaApplication < Application

  REQUEST_TYPES = {
    'LaunchRequest'       => :launch,
    'IntentRequest'       => :intent,
    'SessionEndedRequest' => :end
  }

  def handler(event)
    @event = smart_hash(JSON.parse(event))
    @version = @event.version
    parse_session
    parse_request
    dispatch_response.to_json
  end

  def parse_session
    @session = @event.session
    @application_id = @session.application.applicationId
    @user_id = @session.user.userId
  end

  def parse_request
    @request = @event.request 
    @request_type = REQUEST_TYPES[@request.type]
    @request_id = @request.requestId
  end

  def dispatch_response
    case @request_type
    when :launch
      on_launch
    when :end
      on_end
    when :intent
      self.send("on_#{@request.intent.name}")
    else
      raise "Unknown request type #{@request.type}"
    end
  end

  def on_launch; end
  def on_end; end

  def validate_application_id(application_id)
    raise "AppID does not match #{application_id} != #{@application_id}" if application_id != @application_id
  end

  def speech_response(text)
    {
      'version': '1.0',
      'response': {
        'outputSpeech': {
          'type': 'PlainText',
          'text': text
        },
        'shouldEndSession': true
      }
    }
  end
end
