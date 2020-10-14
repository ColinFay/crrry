
<!-- README.md is generated from README.Rmd. Please edit that file -->

# crrry

<!-- badges: start -->

<!-- badges: end -->

The goal of crrry is to provide some recipes around
[`{crrri}`](https://github.com/RLesur/crrri) for manipulating shiny
applications from the command line.

## Installation

You can install the development version of `{crrry}` from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("ColinFay/crrry")
```

## Starting example

Generate a chrome object connection to a specific app (here, online).

(Note: the `randomPort()` function requires httpuv \>= 1.5.2)

``` r
# install.packages("pagedown")
# install.packages("httpuv")
test <- crrry::CrrryOnPage$new(
  chrome_bin = pagedown::find_chrome(),
  chrome_port = httpuv::randomPort(),
  url = "https://connect.thinkr.fr/prenoms/",
  headless = TRUE
)
#> Running '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
#>   --no-first-run --headless \
#>   '--user-data-dir=/Users/colin/Library/Application Support/r-crrri/chrome-data-dir-ahkcszbz' \
#>   '--remote-debugging-port=18669'
```

Block the process until shiny is ready to continue:

``` r
test$wait_for_shiny_ready()
#> Shiny is computing
#> ✓ Shiny is still running
```

You can send random JavaScript:

``` r
test$call_js(
      '$("#mod_popuui-dep").click()'
    )
#> ── Launching JS: $("#mod_popuui-dep").click() ──────────────────────────
#> Shiny is computing
#> ✓ Shiny is still running
```

`call_js()` returns its value invisibly, but it can be assigned:

``` r
res <- test$call_js(
      '$("#mod_popuui-choix").attr("value")'
    )
#> ── Launching JS: $("#mod_popuui-choix").attr("value") ──────────────────
#> Shiny is computing
#> ✓ Shiny is still running
res
#> $result
#> $result$type
#> [1] "string"
#> 
#> $result$value
#> [1] "Colin"
```

Set the value of a shiny input

``` r
test$shiny_set_input(
    "mod_popuui-depchoice", 
    "59"
  )
#> ── Setting id mod_popuui-depchoice with value 59 ───────────────────────
#> Shiny is computing
#> ✓ Shiny is still running
```

> Note that this doesn’t change the front, only the backend. You won’t
> see the input change with this one, but the reactivity linked to this
> input changes.

Wait for a condition to be true:

``` r
test$wait_for('$("#mod_popuui-depchoice").text() == "01"')
#> Waiting for cond
#> ✓ Shiny is still running
```

Send some gremlins:

``` r
test$gremlins_horde()
#> ── Sending hordes of gremlins ──────────────────────────────────────────
#> Shiny is computing
#> ✓ Shiny is still running
```

Stop the process:

``` r
test$stop()
```

## Use on a local app

``` r
test <- crrry::CrrryProc$new(
  # find the chrome binary
  chrome_bin = pagedown::find_chrome(),
  # Set chrome on a random port
  chrome_port = httpuv::randomPort(),
  # Set shiny on a random port
  shiny_port = httpuv::randomPort(),
  # The code to launch the shiny app
  fun = "hexmake::run_app()",
  # optional code to launch before `fun`
  pre_launch_cmd = "whereami::set_whereami_log('~/Desktop')",
  # Should Chrome be launched headless?
  headless = FALSE
)
#> Running '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
#>   --no-first-run --new-window \
#>   '--user-data-dir=/Users/colin/Library/Application Support/r-crrri/chrome-data-dir-jmjwkfib' \
#>   '--remote-debugging-port=40865'
```

To get the output of the process, run `$stdout()` and `$stderr()`

``` r
test$wait_for_shiny_ready()
#> Shiny is computing
#> ✓ Shiny is still running
test$stderr()
#> Loading required package: shiny
#> Warning: package ‘shiny’ was built under R version 3.6.2
#> 
#> Listening on http://127.0.0.1:11974
#> Warning: The renderImage output named 'main_ui_1-right_ui_1-img' is missing the deleteFile argument; as of Shiny 1.5.0, you must use deleteFile=TRUE or deleteFile=FALSE. (This warning will become an error in a future version of Shiny.)
test$stdout()
#> ── Running server(...) at app_server.R#5 (1) ───────────────────────────
#> ── Running observeEventHandler(...) at mod_manip_image.R#341 (1) ───────
#> ── Running observeEventHandler(...) at mod_rendering.R#74 (1) ──────────
#> ── Running renderImage(...) at mod_right.R#39 (1) ──────────────────────
```

``` r
jsonlite::fromJSON("~/Desktop/whereami.json")
#>   tag                 where
#> 1            app_server.R#5
#> 2     mod_manip_image.R#341
#> 3        mod_rendering.R#74
#> 4            mod_right.R#39
#>                                                          path
#> 1 /Users/colin/Seafile/documents_colin/R/opensource/hexmake/R
#> 2 /Users/colin/Seafile/documents_colin/R/opensource/hexmake/R
#> 3 /Users/colin/Seafile/documents_colin/R/opensource/hexmake/R
#> 4 /Users/colin/Seafile/documents_colin/R/opensource/hexmake/R
#>                  when count
#> 1 2020-10-14 09:06:19     1
#> 2 2020-10-14 09:06:20     1
#> 3 2020-10-14 09:06:20     1
#> 4 2020-10-14 09:06:20     1
```

``` r
test$stop()
```

## Perform a load test

In combination with `{dockerstats}`

``` r
system("docker run -p 2708:80 --rm --name hexmake colinfay/hexmake", wait = FALSE)
Sys.sleep(5)
library(dockerstats)

unlink("inst/dockerstatsss.csv")

tests <- list()

n_users <- 4

append_csv <- function(
  message,
  i
){
  readr::write_csv(
    append = TRUE,
    dockerstats::dockerstats("hexmake", extra = sprintf(
      "%s - %s", message, i
    )),
    "inst/dockerstatsss.csv"
  )
}


for (i in 1:n_users){
  cli::cat_rule(as.character(i))
  tests[[i]] <- crrry::CrrryOnPage$new(
    chrome_bin = pagedown::find_chrome(),
    chrome_port = httpuv::randomPort(),
    url = "http://localhost:2708",
    headless = FALSE
  )
  append_csv( "Connection", i)
}
#> ── 1 ───────────────────────────────────────────────────────────────────
#> Running '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
#>   --no-first-run --new-window \
#>   '--user-data-dir=/Users/colin/Library/Application Support/r-crrri/chrome-data-dir-yavdbbdz' \
#>   '--remote-debugging-port=33636'
#> ── 2 ───────────────────────────────────────────────────────────────────
#> Running '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
#>   --no-first-run --new-window \
#>   '--user-data-dir=/Users/colin/Library/Application Support/r-crrri/chrome-data-dir-rssafsgx' \
#>   '--remote-debugging-port=7631'
#> ── 3 ───────────────────────────────────────────────────────────────────
#> Running '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
#>   --no-first-run --new-window \
#>   '--user-data-dir=/Users/colin/Library/Application Support/r-crrri/chrome-data-dir-vtwpvnof' \
#>   '--remote-debugging-port=17858'
#> ── 4 ───────────────────────────────────────────────────────────────────
#> Running '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
#>   --no-first-run --new-window \
#>   '--user-data-dir=/Users/colin/Library/Application Support/r-crrri/chrome-data-dir-lehxgytx' \
#>   '--remote-debugging-port=41803'

for (i in 1:n_users){
  Sys.sleep(0.5)
  cli::cat_rule(as.character(i))
  tests[[i]]$call_js('$("summary:contains(\'Name\')").click()')
  append_csv( "Clicking on Name", i)
}
#> ── 1 ───────────────────────────────────────────────────────────────────
#> ── Launching JS: $("summary:contains('Name')").click() ─────────────────
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 2 ───────────────────────────────────────────────────────────────────
#> ── Launching JS: $("summary:contains('Name')").click() ─────────────────
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 3 ───────────────────────────────────────────────────────────────────
#> ── Launching JS: $("summary:contains('Name')").click() ─────────────────
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 4 ───────────────────────────────────────────────────────────────────
#> ── Launching JS: $("summary:contains('Name')").click() ─────────────────
#> Shiny is computing
#> ✓ Shiny is still running

for (i in 1:n_users){
  Sys.sleep(0.5)
  cli::cat_rule(as.character(i))
  tests[[i]]$shiny_set_input(
    "main_ui_1-left_ui_1-pkg_name_ui_1-package", 
    "pouet"
  )
  append_csv( "Changin pkg name", i)
}
#> ── 1 ───────────────────────────────────────────────────────────────────
#> ── Setting id main_ui_1-left_ui_1-pkg_name_ui_1-package with value pouet
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 2 ───────────────────────────────────────────────────────────────────
#> ── Setting id main_ui_1-left_ui_1-pkg_name_ui_1-package with value pouet
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 3 ───────────────────────────────────────────────────────────────────
#> ── Setting id main_ui_1-left_ui_1-pkg_name_ui_1-package with value pouet
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 4 ───────────────────────────────────────────────────────────────────
#> ── Setting id main_ui_1-left_ui_1-pkg_name_ui_1-package with value pouet
#> Shiny is computing
#> ✓ Shiny is still running

for (i in 1:n_users){
  Sys.sleep(0.5)
  cli::cat_rule(as.character(i))
  tests[[i]]$gremlins_horde()
  Sys.sleep(5)
  append_csv( "gremlins", i)
}
#> ── 1 ───────────────────────────────────────────────────────────────────
#> ── Sending hordes of gremlins ──────────────────────────────────────────
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 2 ───────────────────────────────────────────────────────────────────
#> ── Sending hordes of gremlins ──────────────────────────────────────────
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 3 ───────────────────────────────────────────────────────────────────
#> ── Sending hordes of gremlins ──────────────────────────────────────────
#> Shiny is computing
#> ✓ Shiny is still running
#> ── 4 ───────────────────────────────────────────────────────────────────
#> ── Sending hordes of gremlins ──────────────────────────────────────────
#> Shiny is computing
#> ✓ Shiny is still running

for (i in 1:n_users){
  Sys.sleep(0.5)
  cli::cat_rule(as.character(i))
  tests[[i]]$stop()
}
#> ── 1 ───────────────────────────────────────────────────────────────────
#> ── 2 ───────────────────────────────────────────────────────────────────
#> ── 3 ───────────────────────────────────────────────────────────────────
#> ── 4 ───────────────────────────────────────────────────────────────────
system("docker kill hexmake")
```

Analyse results

``` r
df <- readr::read_csv(
  "inst/dockerstatsss.csv", 
  col_names = names(dockerstats::dockerstats())
  )
#> Parsed with column specification:
#> cols(
#>   Container = col_character(),
#>   Name = col_character(),
#>   ID = col_character(),
#>   CPUPerc = col_double(),
#>   MemUsage = col_character(),
#>   MemLimit = col_character(),
#>   MemPerc = col_double(),
#>   NetI = col_character(),
#>   NetO = col_character(),
#>   BlockI = col_character(),
#>   BlockO = col_character(),
#>   PIDs = col_double(),
#>   record_time = col_datetime(format = ""),
#>   extra = col_character()
#> )
df$MemUsage <- fs::as_fs_bytes(
  df$MemUsage
)
library(ggplot2)
ggplot() + 
  geom_line(data = df, aes(x = record_time, y = MemUsage)) + 
  scale_y_continuous(labels = scales::label_bytes())
```

<img src="man/figures/README-README-1-1.png" width="100%" />
