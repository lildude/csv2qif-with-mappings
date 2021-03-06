# csv2qif With Mappings

[![GitHub license](https://img.shields.io/github/license/mashape/apistatus.svg)]()

A simple Ruby script to convert bank CSV files to QIF format for importing into things like Quicken or Microsoft Money.

Along with basic CSV-2-QIF conversion, you can also map commonly used names and transaction types to more friendly versions and also map the transactions to categories.

## Installation

```
git clone https://github.com/lildude/csv2qif-with-mappings.git
```

## Usage

```
csv2qif.rb <account_name> </path/to/file.csv>
```

This will save the `.qif` file to the current directory with the same name as the source file, but with a `.qif` extension.

## Configuration

Copy `_config.sample.yml` to `_config.yml` in the directory you cloned the repository into and add accounts and configure your CSV fields to QIF fields.

If you want to do fancy entry rewriting, add those too.
