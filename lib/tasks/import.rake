task :import, [:file] => :environment do |t, args|
  puts "Importing from #{args.file}"

  # these parameters should be in the data file?
  publisher = Publisher.new(:name => "Daily Planet",
                            :theme => "entertainment-daily-planet",
                            :parent => Publisher.find_by_name("Entertainment"))
  if publisher.save

    File.open(args.file).each do |line|
      first_slash = line.index("/")
      if first_slash.nil?   # skip invalid lines
        next
      end
      date_start = line[first_slash-2] == " " ? first_slash-1 : first_slash-2
      ad_client = line[0,date_start].strip
      date_end = line.index(" ", first_slash)
      promo_start = Date.parse(line[date_start, date_end-date_start])

      first_slash = line.index("/", date_end)
      if first_slash
        date_start = line[first_slash-2] == " " ? first_slash-1 : first_slash-2
        date_end = line.index(" ", first_slash)
        promo_end = Date.parse(line[date_start, date_end-date_start])
      else
        promo_end = nil
      end

      # Deal validates for a valid end_at, so no reason to go on here if no end date. Extend in the future to allow this case?
      unless promo_end.nil?
        # could validate presence of [required fields] description, price, and value too, but, really, it's ok to just let the save below fail
        /(?<description>.+)\s+(?<price>\d+)\s+(?<value>\d+$)/ =~ line[date_end,line.length]
        description.strip!

        advertiser = Advertiser.find_by_name(ad_client)
        if advertiser.nil?
          advertiser = Advertiser.new(:name => ad_client, :publisher => publisher)
          advertiser.save
        end
        deal = Deal.new(:advertiser => advertiser,
                        :value => value.to_i,
                        :price => price.to_i,
                        :description => description,
                        :start_at => promo_start,
                        :end_at => promo_end)
        deal.save

        puts "Successfully created a Deal for #{advertiser}. Deal Summary:"
        puts deal.to_yaml
      end
    end
  end
end