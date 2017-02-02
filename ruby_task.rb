require 'watir-webdriver'
require 'nokogiri'
require 'json'
require 'pry'
require 'pry-byebug'
require 'date'

browser = Watir::Browser.new :firefox
browser.goto 'https://wb.micb.md/way4u-wb2/#login'

browser.text_field(:name => 'login').wait_until_present

browser.text_field(:name => 'login').set gets.chomp
browser.text_field(:name => 'password').set gets.chomp
browser.button(:type => 'submit').click

accounts = []
temp = {}

MONTHS = {
	'ianuarie'   => 1,
	'februarie'  => 2,
	'martie'     => 3,
	'aprilie'    => 4,
	'mai'        => 5,
	'iunie'      => 6,
	'iulie'      => 7,
	'august'     => 8,
	'seprembrie' => 9,
	'octombrie'  => 10,
	'noiembrie'  => 11,
	'decembrie'  => 12
}

browser.div(:class => 'contracts-section').wait_until_present

local_data = Nokogiri::HTML(browser.div(:class => 'contracts-section').html)

def base_account_data(page, accounts)
	page.css('div.contract.status-active').each do |data|
		accounts << {
			name:         data.css('a.name').text,
			balance:      data.css('div.balance.available').css('span')[0].text,
			currency:     data.css('div.balance.available').css('span')[1].text,
			transactions: []
		}
	end
end

def reformat_date(bad_format)
	good_format = Date.parse "#{bad_format[:year]}/#{MONTHS[bad_format[:month]]}/#{bad_format[:day]}"
	good_format.strftime('%Y-%m-%d')
	pp good_format.strftime('%Y-%m-%d')
end

def transaction_account_data(page, account)
	temp_date = {}
	transactions = []
	page.css('div.month-delimiter, div.day-operations').each do |operation_row| #first loop
		
		#binding.pry
		
		if operation_row.to_h.has_value? 'month-delimiter'
			temp_date[:month] = operation_row.text.split(' ').first
			temp_date[:year]  = operation_row.text.split(' ').last
			next
		end		
		
		temp_date[:day]   = operation_row.css('div.day-header').text.split(' ').first

		operation_row.css('li.history-item.success').each do |operation| #third loop
			amount = 
				operation.css('span.history-item-amount.total').text.empty? ? 
				operation.css('span.history-item-amount.transaction').css('span[class$="amount"]').text.gsub(',', '.').to_f : 
				operation.css('span.history-item-amount.total').css('span[class$="amount"]').text.gsub(',', '.').to_f

			currency = 
				operation.css('span.history-item-amount.total').text.empty? ? 
				operation.css('span.history-item-amount.transaction').css('span.currency').text : 
				operation.css('span.history-item-amount.total').css('span.currency').text

			amount = "+#{amount}" if operation.css('span.history-item-amount.transaction').to_s.include? 'income'

			date = reformat_date(temp_date)

			transactions << {
				date:        date,
				description: operation.css('a.operation-details').text,
				amount:      amount,
				currency:    currency
			}	
			account[:transactions] << transactions

		end #third loop
	end #first loop
end #function

base_account_data(local_data, accounts)

accounts.each do |account|
	browser.a(:title => account[:name]).wait_until_present
	sleep 1
	browser.a(:title => account[:name]).click
	browser.ul(:class => 'ui-tabs-nav').wait_until_present
	browser.a(:href => '#contract-information').click
	
	account[:description] = browser.element(:xpath => '//*[@id="contract-information"]/table/tbody/tr[3]/td[2]').text
	account[:holder_name] = browser.element(:xpath => '//*[@id="contract-information"]/table/tbody/tr[4]/td[2]').text
	
	browser.a(:href => '#contract-history').wait_until_present
	browser.a(:href => '#contract-history').click
	browser.div(:class => 'filter filter_period').wait_until_present
	browser.input(:name => 'from').click
	browser.a(:class => 'ui-datepicker-prev').wait_until_present
	browser.a(:class => 'ui-datepicker-prev').click
	browser.table(:class => 'ui-datepicker-calendar').a(:text => '1').wait_until_present
	browser.table(:class => 'ui-datepicker-calendar').a(:text => '1').click
	
	browser.div(:class => 'operations').wait_until_present
	sleep 1
	local_data = Nokogiri::HTML(browser.div(:class => 'operations').html)
	
	transaction_account_data(local_data, account)
	pp account
	browser.a(:href => '#menu/MAIN_MENU_WB2.NEW_CARDS_ACCOUNTS').click
	
end
binding.pry
JSON.pretty_generate(accounts)

#binding.pry
