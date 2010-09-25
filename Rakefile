require 'rubygems'  
require 'rake'  
require 'echoe'  
  
Echoe.new('elastic_attributes', '0.1.0') do |p|  
  p.description     = "Flexible attribute mapping"  
  p.url             = "http://github.com/bagilevi/elastic_attributes"  
  p.author          = "Levente Bagi"  
  p.email           = "bagilevi@gmail.com"  
  p.ignore_pattern  = []  
  p.development_dependencies = []  
end  
  
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }