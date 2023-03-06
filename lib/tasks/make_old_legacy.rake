desc "make all old rules legacy"
task :make_old_legacy => :environment do
    rules = Rule.all
    rules.each do |r|
        r.legacy = true
        r.save
    end
end
