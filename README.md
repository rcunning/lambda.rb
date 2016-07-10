# lambda.rb

## What can you do with it?

- Write ruby 2.2 (or other [Travelling Ruby](http://phusion.github.io/traveling-ruby/) version) code that runs on AWS Lambda
- Write ruby code that handles Alexa Skills requests

## E.g.

- hello-world
```ruby
require File.join(File.dirname(__FILE__), 'application.rb')

class HelloWorld < Application
  @@application_class = HelloWorld

  def handler(event)
    @event = JSON.parse(event)
    "Got this event - #{@event.to_json}"
  end
end
```

- hello-world-alexa
```ruby
require File.join(File.dirname(__FILE__), 'application.rb')
require File.join(File.dirname(__FILE__), 'alexa', 'alexa_application.rb')

class HelloWorldAlexa < AlexaApplication
  @@application_class = HelloWorldAlexa 
  @@application_id = 'amzn1.echo-sdk-ams.app.[xxx]'

  def on_launch(response)
    response.speak_text('Hello from ruby')
  end

  def on_SomeIntent(response)
    response.speak_text("I got this in myslot #{@request.intent.slots.myslot.value}")
  end

  def on_SomeOtherIntent(response)
    response.play_mp3('http://myhost.com/ding_dong.mp3')
  end

  def on_SomeOtherMoreComplicatedIntent(response)
    response.speak_text("Very nice!")
      .with_card(AlexaResponse.card_options('My App Card Title', 'May App Card Contents'))
      .with_reprompt(AlexaResponse.speech_options('What do you want to do next?'))
  end
end
```

## How to use

1. Setup everything AWS
  - Sign up for Amazon AWS
  - Get access to Amazon S3
  - Get access to Amazon Lambda
  - Create an IAM account with access to S3 and Lambda
  - Install the aws cli tools
  - Set up an AWS profile in `~/.aws/credentials` for the account created above
2. Create your project
  - $ git clone git@github.com:rcunning/lambda.rb.git
  - $ cd lambda.rb
  - $ rake create[../new-function]
3. Add your credentials and AWS settings
  - Edit ../new-function/lambda.rb.yaml
  - Make sure to replace your aws_profile name, aws_bucket, aws_subdir
4. Create your AWS Lambda function in the [AWS console](https://console.aws.amazon.com/lambda/home)
  - Make sure to name it to match new-function
  - Make sure to choose Node 4.3, at least 512 MB memory, at least 10 seconds timeout
  - If creating an Alexa Skill, use the Alexa JS sample when creating it
5. Edit your code
  - $ vi ../new-function/app/new-function.rb
  - Start with something like the e.g. section above
  - For Alexa be sure to [create your Alexa](https://developer.amazon.com/edw/home.html#/) app and get its id
6. Test your code
  - $ rake test[ping]
  - or for Alexa
  - $ rake test[alexa/launch]
7. Deploy your code
  - $ rake deploy

lambda.rb keeps the last used directory as its working target. See the other options
  - $ rake -T

## Notes

- started with https://github.com/lorennorman/ruby-on-lambda
- execution time is about 200 ms slower per request than JS or python on AWS Lambda
