# Greeter Class
# Used to greet people
class Greeter
  # Initialize the greeter with a name.
  def initialize(name)
    @name = name
  end

  # Display the greeting.
  def greet
    puts "Hello, #{name}"
  end
  
  def name
    @name
  end
end
