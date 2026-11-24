# Upload metadata, search terms, and staff/patron fields are private too.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :code, :state, :query, :name, :address, :phone, :card, :description, :violation,
  :behavior, :comment, :text, :note, :body, :information, :image, :pic, :letter
]
