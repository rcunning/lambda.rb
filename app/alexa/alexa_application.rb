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
  # redefine this in your class, only one class per process
  @@log_request = true
  @@log_session = false
  @@application_id = 'amzn1.echo-sdk-ams.app.[unique-value-here]'
  @@validate_application_on_every_request = true

  attr_reader :session, :new_session, :session_id, :application_id, :session_attributes,
              :user_id, :access_token, :request, :request_type, :request_id, :intent

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
    dispatch_session
    dispatch_response.to_json
  end

  def parse_session
    @session = @event.session
    @new_session = @session.new
    @session_id = @session.sessionId
    @application_id = @session.application.applicationId
    @session_attributes = @session.attributes || {}
    @user_id = @session.user.userId
    @access_token = @session.user.accessToken
  end

  def parse_request
    @request = @event.request 
    @request_type = REQUEST_TYPES[@request.type]
    @request_id = @request.requestId
    @intent = @request_type == :intent ? @request.intent.name.sub(/\./,'_') : @request_type
  end

  def dispatch_session
    on_new_session if @new_session
  end

  def dispatch_response
    log("on_#{@intent} with request #{@request.to_json}#{" session #{@session}" if @@log_session}") if @@log_request
    validate_application_id if @@validate_application_on_every_request
    @response = AlexaResponse.new(@session)
    send("on_#{@intent}", @response)
  end

  # override these
  def on_new_session(); end
  def on_launch(response)
    response.none
  end
  def on_end(reponse)
    response.none
  end

  def validate_application_id
    raise "AppID does not match #{@application_id} != #{@@application_id}" if @application_id != @@application_id
  end
end

class AlexaResponse

  def initialize(session)
    @session = session
  end

  def to_json
    @response.to_json
  end

  def none
    build_response({ :end_session => true })
  end

  # quick helpers
  def speak_text(text, options = {})
    build_response(options.merge({:text => text}))
    self
  end
  def speak_ssml(ssml, options = {})
    build_response(options.merge({:ssml => ssml}))
    self
  end
  def play_mp3(url, options = {})
    build_response(options.merge({:ssml => "<speak><audio src=\"#{url}\" /></speak>"}))
    self
  end

  def speak_text_with_card(text, card, options = {})
    speak_text(text, options.merge({:card => card}))
  end
  def speak_ssml_with_card(ssml, card, options = {})
    speak_ssml(ssml, options.merge({:card => card}))
  end
  def play_mp3_with_card(ssml, card, options = {})
    speak_ssml(ssml, options.merge({:card => card}))
  end

  def ask_text(text, reprompt, options = {})
    speak_text(text, options.merge({:reprompt => reprompt}))
  end
  def ask_ssml(ssml, reprompt, options = {})
    speak_ssml(ssml, options.merge({:reprompt => reprompt}))
  end
  def ask_mp3(ssml, reprompt, options = {})
    speak_ssml(ssml, options.merge({:reprompt => reprompt}))
  end

  def ask_text_with_card(text, reprompt, card, options = {})
    speak_text(text, options.merge({:reprompt => reprompt, :card => card}))
  end
  def ask_ssml_with_card(ssml, reprompt, card, options = {})
    speak_ssml(ssml, options.merge({:reprompt => reprompt, :card => card}))
  end
  def ask_mp3_with_card(ssml, reprompt, card, options = {})
    speak_ssml(ssml, options.merge({:reprompt => reprompt, :card => card}))
  end

  # use these to build the options for reprompt args or card args
  def speech_options(text, ssml = nil)
    text ? { :text=>text } : { :ssml=>ssml }
  end

  def card_options(card_type, card_title, card_content)
    { :card_type => card_type, :card_title => card_title, :card_content => card_content }
  end

  # details
  def build_response(options)
    @response = { 'version': '1.0' }
    add_session(options)
    add_response(options)
    self
  end

  def add_session(options)
    @response['sessionAttributes'] = @session.attributes || {}
  end

  def add_response(options)
    @response['response'] = {
      'shouldEndSession': options.nil? || options[:end_session].nil? ? true : !!options[:end_session]
    }
    add_output(options)
    add_card(options)
    add_reprompt(options)
  end

  def add_output(options)
    @response['response']['outputSpeech'] = speech(options)
  end

  def add_card(options)
    if options[:card]
      @response['response']['card'] = card(options)
    end
  end

  def add_reprompt(options)
    if options[:reprompt]
      @response['response']['shouldEndSession'] = false
      @response['response']['reprompt'] = { 'outputSpeech': speech(options[:reprompt]) }
    end
  end

  def speech(options)
    if options[:ssml]
      {
        'type': 'SSML',
        'ssml': options[:ssml]
      }
    else
      {
        'type': options[:type] || 'PlainText',
        'text': options[:text]
      }
    end
  end

  def card(options)
    card = {
      'type': ptions[:card_type] || 'Simple',
      'title': options[:card_title] || 'Card Title',
      'content': options[:card_content] || 'Card Contents'
    }
    if options[:image_small] && options[:image_large]
      card.merge!({
        'type' => 'Standard',
        'image' => {
          'smallImageUrl' => options[:image_small],
          'largeImageUrl' => options[:image_large],
        }
      })
    end
    card
  end
end
