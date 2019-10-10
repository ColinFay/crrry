#' @export
Crrry <- R6::R6Class(
  "Crrry",
  public = list(
    initialize = function(
      chrome_bin = Sys.getenv("HEADLESS_CHROME"),
      fun = "pkgload::load_all();run_app()",
      shiny_port = 2811L,
      chrome_port = 9222L,
      ...
    ){
      browser()
      chrome <- crrri::Chrome$new(
        chrome_bin,
        debug_port = chrome_port,
        ...
      )
      Sys.sleep(2)
      private$client <- chrome$connect(callback = function(client) {
        #browser()
        client$inspect(TRUE)
      })
      private$Page <-  private$client$Page
      private$Runtime <-  private$client$Runtime
      private$process <- processx::process$new(
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
        private$process$is_alive(),
        msg = "Unable to launch the Shiny App"
      )
      Sys.sleep(2)
      private$client$Page$navigate(
        url = sprintf(
          "http://127.0.0.1:2811",
          shiny_port
          )
        )
    },
    click = function(on, check = TRUE){
      private$Runtime$evaluate(
        expression = sprintf(
          '$("%s").click()',
          on
        )
      )
      if (check){
        sleep_while_shiny_busy(private$Runtime)
        check_still_running(private$Runtime)
      }
    },
    stop = function(){
      private$process$kill()
    },
    is_alive = function(){
      private$process$is_alive()
    }
  ),
  private = list(
    Page = NULL,
    Runtime = NULL,
    process = NULL,
    client = NULL,
  )
)
