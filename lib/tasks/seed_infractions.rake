desc "seed rules from csv"
task :seed_rules => :environment do
    require 'csv'
    CSV.foreach("#{Rails.root}/db/rules.csv", :encoding => 'windows-1251:utf-8') do |x|
        r = Rule.new
        puts x[1]
        r.description = x[1]
        r.track = x[0]
        if r.valid?
            r.save!
        end
    end
end
