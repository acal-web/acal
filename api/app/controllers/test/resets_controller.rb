module Test
  class ResetsController < ApplicationController
    def create
      raise "test-only endpoint" unless Rails.env.test?
      Test::DatabaseReset.call
      head :no_content
    end
  end
end
