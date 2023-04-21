desc "import old reports from csv"
task :import_reports => :environment do
    require 'csv'
    require 'open-uri'
    require 'net/http'

    i = 0
    CSV.foreach("#{Rails.root}/import/data.csv", :encoding => 'windows-1251:utf-8') do |x|
        i += 1
    end
    puts "there were #{i} rows in the csv"

    reports = CSV.read("#{Rails.root}/import/data.csv", :encoding => 'windows-1251:utf-8', :headers => true)

    puts "there are #{reports.count} reports in the array"
    puts reports[0][0]

    def process_date(date_string)
        match_data = date_string.split('/')
        month = match_data[0].to_i
        day = match_data[1].to_i
        year = match_data[2].to_i
        date = Date.new(year, month, day)
        return date
    end


    reports.each do |r|
        puts r[3] + " " + r[1]
        report = Oldreport.new
        report.legacy_id = r[0]
        report.date_of = process_date(r[1])
        puts "report date " + report.date_of.to_s + 'raw value ' + r[1]
        report.time_of = Time.parse(r[2]) rescue nil
        puts "report time " + report.time_of.to_s
        report.title = r[3]
        report.patron_name = r[4]
        report.patron_address = r[5]
        report.description = r[6]
        report.narrative = r[7]
        report.location = r[8]
        report.date_entered = Date.parse(r[9])
        puts "report date " + report.date_entered.to_s + 'raw value ' + r[9]
        report.submitted_by = r[10]
        report.suspension = r[11]
        report.suspension_duration = r[12]
        report.violation_number = r[13]
        report.a_violations = r[14]
        report.b_violations = r[15]
        urls = eval(r[16])
        urls.each do |url|
            uri = URI.parse(url)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true if uri.scheme == 'https'
            response = http.get(uri.request_uri)
            io = StringIO.new(response.body)
            filename = File.basename(uri.path)
            report.images.attach(io: io, filename: filename)
        end
        report.save
    end
end
