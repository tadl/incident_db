class ApplicationJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError, ActiveRecord::RecordNotFound
end
