require 'httparty'
require 'mechanize'


def ilscatcher3_holdings
    ilscatcher3_url = 'https://catalog.tadl.org/main/details.json?id=48285653'
    ilscatcher3_response = HTTParty.get(ilscatcher3_url).parsed_response
    return ilscatcher3_response['holdings']
end

def mobile_holdings
    mobile_url = 'https://tadlmobile.apps.tadl.org/details.json?id=48285653'
    mobile_response = HTTParty.get(mobile_url).parsed_response
    return mobile_response['holdings']
end

def evergreen_holdings
    evergreen_url = 'https://mr-v2a.catalog.tadl.org/eg/opac/record/48285653?query=hotspot;qtype=keyword;locg=1;copy_offset=0;copy_limit=50'
    agent = Mechanize.new
    page = agent.get(evergreen_url)
    holdings = []
    page.parser.css('.copy_details_table').css('tr').css('.copy_details_offers_row').each do |t|
        item = {}
        item['barcode'] = t.css('td[3]').text.strip
        item['status'] = t.css('td[5]').text.strip
        item['due_date'] = t.css('td[6]').text.strip
        if item['status'] == "Checked out"
            split_date = item['due_date'].split('/')
            item['due_date'] = split_date[2] + '-'+ split_date[0] + '-'+ split_date[1]
        end
        holdings.push(item)
    end
    return holdings
end

time_start = Time.now

@errors = []
@ilscatcher3_holdings = ilscatcher3_holdings
@mobile_holdings = mobile_holdings


evergreen_holdings.each do |h|
    # first check mobile
    mobile_item = @mobile_holdings.find {|k| k['barcode'] == h['barcode']}
    if mobile_item['status'] != h['status']
        error = 'Item with barcode ' + h['barcode'] + ' has an inacurate status in mobile index'
        @errors.push(error)
    end
    if h['status'] == 'Checked out' && mobile_item['status'] == 'Checked out'
        if h['due_date'] != mobile_item['due_date']
            error = 'Item with barcode ' + h['barcode'] + ' has an inacurate due date in mobile index'
            @errors.push(error)
        end
    end
    #now check ilscatcher3
    ilscatcher3 = @ilscatcher3_holdings.find {|k| k['barcode'] == h['barcode']}
    if ilscatcher3['status'] != h['status']
        error = 'Item with barcode ' + h['barcode'] + ' has an inacurate status in ilscatcher3 index'
        @errors.push(error)
    end
    if h['status'] == 'Checked out' && ilscatcher3['status'] == 'Checked out'
        if h['due_date'] != ilscatcher3['due_date']
            error = 'Item with barcode ' + h['barcode'] + ' has an inacurate due date in ilscatcher3 index'
            @errors.push(error)
        end
    end
end

@errors.each do |e|
    puts e
end

time_end = Time.now
time_complete = time_end - time_start

puts 'test ran in ' + time_complete.to_s + ' seconds'