#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'qif'
require 'csv'
require 'yaml'

account = ARGV[0].to_sym
file_path = ARGV[1]

output_file = File.basename(file_path).sub!('csv', 'qif')

# Recursively convert key strings in the YAML to symbols
def symbolize_keys(hash)
  hash.inject({}) do |result, (key, value)|
    new_key = case key
              when String then key.to_sym
              else key
              end
    new_value = case value
                when Hash then symbolize_keys(value)
                else value
                end
    result[new_key] = new_value
    result
  end
end

# Stringify the keys in a hash when we need to.
def stringify_keys(hash)
  hash.inject({}) do |result, (key, value)|
    result[key.to_s] = value
    result
  end
end

# Determine the "amount" value
def calculate_amount(row, acc_cfg)
  if acc_cfg[:csv_field_map][:amount].nil?
    if row[acc_cfg[:csv_field_map][:amount_in]].to_f == 0
      -row[acc_cfg[:csv_field_map][:amount_out]].to_f
    else
      row[acc_cfg[:csv_field_map][:amount_in]].to_f
    end
  end
end

# Read in configuration yaml file
config = symbolize_keys(YAML.load_file('_config.yml'))

acc_cfg = config[:accounts][account]

# Read in the csv file
bank_file = File.read(file_path).force_encoding('utf-8')
bank_file = CSV.parse(bank_file, col_sep: acc_cfg[:col_sep].nil? ? config[:col_sep] : acc_cfg[:col_sep])


Qif::Writer.open(output_file, type = acc_cfg[:type], format = acc_cfg[:date_fmt]) do |qif|
  # Uncomment this when https://github.com/jemmyw/Qif/pull/13 is merged.
  #qif << Qif::Account.new(
  #  :name         => acc_cfg[:name],
  #  :type         => acc_cfg[:type],
  #  :description  => ( acc_cfg[:description] unless acc_cfg[:description].nil? ),
  #  :limit        => ( acc_cfg[:limit] unless acc_cfg[:limit].nil? ),
  #  :balance_date => ( acc_cfg[:balance_date] unless acc_cfg[:balance_date].nil? ),
  #  :balance      => ( acc_cfg[:balance] unless acc_cfg[:balance].nil? ),
  #)
  bank_file.each do |row|
    next if ( row.empty? || row[0] == "Date" )  # Assumes the CSV file header line starts with "Date"
    row.each { |value| value.to_s.gsub!(/^\s+|\s+$/,'') }
    date = row[0].split("/").reverse.join("/")
    qif << Qif::Transaction.new(
      :date               => row[acc_cfg[:csv_field_map][:date]],
      :amount             => calculate_amount(row, acc_cfg),
      :payee              => row[acc_cfg[:csv_field_map][:payee]],
      :number             => ( row[acc_cfg[:csv_field_map][:number]].gsub!(/.*/, stringify_keys(acc_cfg[:number_map])) unless acc_cfg[:csv_field_map][:number].nil? ),
      :memo               => ( row[acc_cfg[:csv_field_map][:memo]] unless acc_cfg[:csv_field_map][:memo].nil? ),
      :status             => ( row[acc_cfg[:csv_field_map][:status]] unless acc_cfg[:csv_field_map][:status].nil? ),
      :adress             => ( row[acc_cfg[:csv_field_map][:adress]] unless acc_cfg[:csv_field_map][:adress].nil? ),
      :category           => ( row[acc_cfg[:csv_field_map][:category]] unless acc_cfg[:csv_field_map][:category].nil? ),
      :split_category     => ( row[acc_cfg[:csv_field_map][:split_category]] unless acc_cfg[:csv_field_map][:split_category].nil? ),
      :split_memo         => ( row[acc_cfg[:csv_field_map][:split_memo]] unless acc_cfg[:csv_field_map][:split_memo].nil? ),
      :split_amount       => ( row[acc_cfg[:csv_field_map][:split_amount]] unless acc_cfg[:csv_field_map][:split_amount].nil? ),
    )
  end
end
