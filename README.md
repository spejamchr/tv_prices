# TV Prices

> Scrape, record, and analyze television data from online retailers

This is mostly a collection of scripts for scraping television data, recording
that data, and analyzing those records across time.

## Start

```shell
❯ git clone git@github.com:spejamchr/tv_prices.git
❯ cd tv_prices
❯ bundle

# Scrape current television data
❯ ruby scripts/scrape.rb
```

## Requirements

- Ruby ~> 2.6

## Usage

There are several different scripts, which use the internal tools in `lib/`.

- Scrape
- Reformat
- Analyze

### Scrape Fresh Data

```shell
❯ ruby scripts/scrape.rb
```

This creates a cache of the HTML/JSON files so that developing the scripts
can be fast & repeatable. In order to scrape some more fresh data delete the
cache directory and rerun the scrape script:

```shell
❯ rm -rf cached_pages
❯ ruby scripts/scrape.rb
```

### Reformat Historical Data

```shell
❯ ruby scripts/reformat_history.rb
```

If the format of the exported `.csv` files changes this can help convert all
historical data to the same format. This is not very battle-hardened, so
tweaking may be necessary depending on the nature of the change in format.

### Analyze Historical Data

```shell
❯ ruby scripts/analyze_history.rb
```

Run some simple analysis on the historical records.

## Scraping Stores

Stores can be scraped either in HTML or JSON. Adding a new store to scrape is
done entirely within [`config/application.yml`][config], and takes about a dozen
lines of code. Currently scraped stores are:

- [Amazon][amazon] (HTML)
- [Best Buy][bestbuy] (HTML)
- [Costco][costco] (HTML)
- [Ebay][ebay] (HTML)
- [Fry's][frys] (HTML)
- [Newegg][newegg] (HTML)
- [Overstock][overstock] (JSON)
- [Target][target] (JSON)
- [Walmart][walmart] (JSON)

## License

All code and data are released under the terms of the [MIT License][mit].

[config]: https://github.com/spejamchr/tv_prices/blob/master/config/application.yml
[amazon]: https://www.amazon.com
[bestbuy]: https://www.bestbuy.com
[costco]: https://www.costco.com
[ebay]: https://www.ebay.com
[frys]: https://www.frys.com
[newegg]: https://www.newegg.com
[overstock]: https://www.overstock.com
[target]: https://www.target.com
[walmart]: https://www.walmart.com
[mit]: https://opensource.org/licenses/MIT
