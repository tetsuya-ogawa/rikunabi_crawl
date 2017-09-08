require 'anemone'
require "google_drive"
(1..294).each do |time|
  datas = []
  session = GoogleDrive::Session.from_service_account_key('keyfile.json')
  ws = session.spreadsheet_by_key('1Oao7PU6MW0oeDrmN_H5hUwASEMH-kdFyFsXwNXiUbO8').worksheets[0]
  # ws = session.spreadsheet_by_key('1Dplo6n7XXrFtT1y_ieeeOizUN3mVvPHox2fRp74C-Pw').worksheets[0]
  Anemone.crawl("https://job.rikunabi.com/2018/s/__________/?moduleCd=2&isc=ps055&pn=#{time}", delay: 4) do |anemone|
    anemone.focus_crawl do |page|
      page.links.keep_if { |link|
        link.to_s.match(/^https:\/\/job.rikunabi.com\/2018\/company\/r[0-9]*\/$/)
      }
    end
    anemone.on_every_page do |page|
      data = {
        '社名' => page.doc.xpath('/html/body/div[1]/div[2]/div[1]/div[1]/div[1]/h1/a')&.text,
        '電話番号' => page.doc.xpath('//*[@id="company-data04"]/div')&.text.tr("０-９", "0-9").scan(/(\(?\d{2,5}[-)(\sー‐－]\d{1,4}[-)\sー‐－]\d{2,4}|0120-\d{6})/).join(','),
        'メール' => page.doc.xpath('//*[@id="company-data04"]/div')&.text.scan(/[\w+\-.]+[@★][a-z\d\-.]+\.[a-z]+/).join(','),
        '業種' => page.doc.xpath('/html/body/div[1]/div[2]/div[1]/div[1]/div[3]/table/tr[1]/td/div[1]').text,
        '職種' => page.doc.xpath('/html/body/div[1]/div[2]/div[1]/div[1]/div[3]/table/tr/td/div[2]').text,
        '本社' => page.doc.xpath('/html/body/div[1]/div[2]/div[1]/div[1]/div[3]/table/tr[2]/td/div[1]').text,
        '従業員数' => page.doc.xpath('/html/body/div[1]/div[2]/div').text.match(/(\n.*従業員数.*\n.+\n|\n.*社員数.*\n.+\n)/).to_s.tr("０-９", "0-9").gsub(/\r/, ',').gsub(/(従業員数|社員数|\n)/, '').match(/[\d,]+/),
        '募集人数' => page.doc.xpath('/html/body/div[1]/div[2]/div[1]/div[2]/table/tr/td/div').text.match(/\d+名/).to_s&.gsub(/名/, ''),
        '更新日' => page.doc.xpath('/html/body/div[1]/div[2]/div[1]/div[2]/table/tr/td/div').text.match(/\d{4}\/\d{2}\/\d{2}/),
        '従業員数（原文）' => page.doc.xpath('/html/body/div[1]/div[2]/div').text.match(/(\n.*従業員数.*\n.+\n|\n.*社員数.*\n.+\n)/).to_s.gsub(/\r/, ',').gsub(/(従業員数|社員数|\n)/, ''),
        '連絡先（原文）' => page.doc.xpath('//*[@id="company-data04"]/div')&.text.tr("０-９", "0-9").to_s,
        'URL' => page.url.to_s
      }
      datas << data
      puts data
      ws.list.push(
        data.each do |k, v|
          [k.to_s => v.to_s]
        end
      )
      # ws.save
    end
  end
  ws.save
end
