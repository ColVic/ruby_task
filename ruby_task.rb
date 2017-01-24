require 'watir'
require 'json'

browser = Watir::Browser.new
browser.goto 'https://wb.micb.md/way4u-wb2/#login'

browser.text_field(:name => 'login').set 'bah4uk' #gets.chomp
browser.text_field(:name => 'password').set '34erdfCV5' #gets.chomp
browser.button(:type => 'submit').click

accounts = []
acc_name, acc_balance, acc_currency, acc_description = [], [], [], []
transactions_to_account = []
transactions = []
trans_date, tran_description, trans_amount = [], [], []

class Account
	attr_accessor :a_name, :balance, :currency, :description, :transactions

	def initialize(params = {})
		@a_name = params.fetch(:a_name, '')
		@balance = params.fetch(:balance, 0)
		@currency = params.fetch(:currency, '')
		@description = params.fetch(:description, '')
		@transactions = params.fetch(:transactions, [])
	end

	def to_hash
    hash = {}
    instance_variables.each {|var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
    hash
  end

end

class Transaction < Account
	attr_accessor :date, :description, :amount

	def initialize(params = {})
		@date = params.fetch(:date, 'yy-mm-ddTh-i-s')
		@description = params.fetch(:description,'')
		@amount = params.fetch(:amount, 0)
	end

end

browser.div(:class => 'contract').a(:class => 'name').wait_until_present

browser.divs(:class => 'contract status-active ').each_with_index do |contract_div, i| #first loop start
	acc_name[i] = contract_div.a(:class => 'name').text
	acc_balance[i] = contract_div.div(:class => 'balance available').span.text
	acc_currency[i] = contract_div.div(:class => 'balance available').span(:class => 'currency').text

	contract_div.a(:class => 'name').click
	browser.a(:href => "#contract-information").click

	acc_description[i] = browser.element(:xpath => '//*[@id="contract-information"]/table/tbody/tr[3]/td[2]').text

	browser.a(:href => '#contract-history').click
	browser.a(:class => 'operation-details').wait_until_present

	browser.divs(:class => 'day-operations').each_with_index do |transaction, j| #second loop start
		trans_date[j] = 'yy-mm-ddTh-i-s'
		tran_description[j] = transaction.a(:class => 'operation-details').text
		trans_amount[j] = transaction.span(:class => 'history-item-amount transaction ').span.text
		transactions_to_account[j] = Transaction.new(:date => trans_date[j], :description => tran_description[j], :amount => trans_amount[j]).to_hash
		transactions << transactions_to_account[j]
	end #second loop end

	browser.li(:class => 'new_cards_accounts-menu-item').click
	accounts[i] = Account.new(:a_name => acc_name[i], :balance => acc_balance[i], :currency => acc_currency[i], :description => acc_description[i], :transactions => transactions_to_account).to_hash
	transactions_to_account = []
end #first loop end

def result
	accounts.each do |account|
	end
end

puts JSON.pretty_generate(accounts)



