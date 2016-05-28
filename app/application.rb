# extend this class and redefine @@application_class to your class
class Application
  @@application_class = Application

  def self.init
    @@application_class.new
  end

  # default handler simply returns the event object
  def handler(event)
    event
  end

  def log(s)
    $stderr.write("#{s}\n")
  end
end
