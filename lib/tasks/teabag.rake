desc "Run the javascript specs"
task :teabag => :environment do
  require "teabag/console"
  fail if Teabag::Console.new({suite: ENV["suite"]}).execute
end
task :sage_teabag => :environment do
  require "teabag/sage_console"
  fail if Teabag::SageConsole.new({suite: ENV["suite"]}).execute
end
