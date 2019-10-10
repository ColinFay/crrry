
<!-- README.md is generated from README.Rmd. Please edit that file -->

# crrry

<!-- badges: start -->

<!-- badges: end -->

The goal of crrry is to …

## Installation

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("ColinFay/crrry")
```

## This works :

``` r
chrome_bin = pagedown::find_chrome()
chrome_port = 12345L
shiny_port = 2811
fun = 'shiny::runExample("01_hello")'
chrome <- crrri::Chrome$new(
  chrome_bin,
  debug_port = chrome_port
)
client <- chrome$connect(callback = function(client) {
  client$inspect(FALSE)
})

Page <-  client$Page
Runtime <-  client$Runtime
process <- processx::process$new(
  "Rscript", c(
    "-e",
    sprintf(
      "options(shiny.port = %s);%s",
      shiny_port, fun
    ),
    stderr = "|", stdout = "|"
  )
)
attempt::stop_if_not(
  process$is_alive(),
  msg = "Unable to launch the Shiny App"
)
client$Page$navigate(
  url = sprintf(
    "http://127.0.0.1:2811",
    shiny_port
  )
)
chrome$close()
```

But not when put into an R6:

``` r
pkgload::load_all()
test <- crrry::Crrry$new(
  chrome_bin = pagedown::find_chrome(), 
  chrome_port = 12345L, 
  fun = 'shiny::runExample("01_hello")'
)
```

    Running '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
    --no-first-run --headless \
    '--user-data-dir=/Users/colin/Library/Application Support/r-crrri/chrome-data-dir-aekovtbn' \
    '--remote-debugging-port=12345'
    Unhandled promise error: invalid state

``` r
plop <- R6::R6Class(
  "plop", 
  public = list(
    initialize = function(){
      chrome_bin = pagedown::find_chrome()
      chrome_port = 12347L
      shiny_port = 2811
      fun = 'shiny::runExample("01_hello")'
      chrome <- crrri::Chrome$new(
        chrome_bin,
        debug_port = chrome_port
      )
      client <- chrome$connect(callback = function(client) {
        client$inspect(FALSE)
      })
      
      Page <-  client$Page
      Runtime <-  client$Runtime
      process <- processx::process$new(
        "Rscript", c(
          "-e",
          sprintf(
            "options(shiny.port = %s);%s",
            shiny_port, fun
          ),
          stderr = "|", stdout = "|"
        )
      )
      attempt::stop_if_not(
        process$is_alive(),
        msg = "Unable to launch the Shiny App"
      )
      client$Page$navigate(
        url = sprintf(
          "http://127.0.0.1:2811",
          shiny_port
        )
      )
      chrome$close()
    }
  )
)
plop$new()
```

    Running '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
      --no-first-run --headless \
      '--user-data-dir=/Users/colin/Library/Application Support/r-crrri/chrome-data-dir-nqwzjnqs' \
      '--remote-debugging-port=12347'
    Unhandled promise error: invalid state
    <plop>
      Public:
        clone: function (deep = FALSE) 
        initialize: function ()
