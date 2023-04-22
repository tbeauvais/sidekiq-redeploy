# frozen_string_literal: true

Dir.glob("#{__dir__}/sidekiq/redeploy/**/*.rb").each { |file| require file }

module Sidekiq
  module Redeploy
    class Error < StandardError; end
    # Your code goes here...
  end
end
