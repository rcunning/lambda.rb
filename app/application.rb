# extend this class and redefine @@application_class to your class
class Application
  @@application_class = Application

  def self.init
    @@application_class.new
  end

  # default handler simly returns the event object
  def handler(event)
    event
  end
end