# Keep incident content and patron details out of request logs.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :code, :state, :query, :name, :address, :phone, :card, :description, :violation,
  :behavior, :comment, :text, :note, :body, :information, :image, :pic, :letter,
  :title, :location, :date_of, :city, :zip, :until, :call_police, :pending_patrons
]
