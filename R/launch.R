#' @export
Crrry <- R6::R6Class(
  "Crrry",
  public = list(
    process = NULL,
    initialize = function(
      chrome_bin = Sys.getenv("HEADLESS_CHROME"),
      fun = "pkgload::load_all();run_app()",
      shiny_port = 2811L,
      chrome_port = 9222L,
      inspect = TRUE,
      ...
    ){
      self$process <- processx::process$new(
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
        self$process$is_alive(),
        msg = "Unable to launch the Shiny App"
      )

      private$chrome <- crrri::Chrome$new(
        chrome_bin,
        debug_port = chrome_port,
        ...
      )
      private$client <- crrri::hold(
        private$chrome$connect()
      )

      private$Page <-  private$client$Page
      private$Runtime <-  private$client$Runtime

      crrri::hold({
        private$client$Page$navigate(
          url = sprintf(
            "http://127.0.0.1:%s",
            shiny_port
          )
        )
      })
      #browser()
      #crrri::hold({
        private$client$inspect(inspect)
      #})

      #sleep_while_shiny_busy(private$Runtime)
    },
    call_js = function(code, check = TRUE){
      crrri::hold({
        private$Runtime$evaluate(
          expression = code
        )
      })
      maybe_check(check, private)
    },
    click_on_id = function(id, check = TRUE){
      crrri::hold({
        private$Runtime$evaluate(
          expression = sprintf(
            'document.getElementById("%s").click()',
            id
          )
        )
      })
      maybe_check(check, private)
    },
    shiny_set_input = function(id, val, check = TRUE){
      crrri::hold({
        private$Runtime$evaluate(
          expression = sprintf(
            'Shiny.setInputValue("%s", "%s")',
            id, val
          )
        )
      })
      maybe_check(check, private)
    },
    wait_for_shiny_ready = function(check = TRUE){
      sleep_while_shiny_busy(private$Runtime)
      if(check){
        check_still_running(private$Runtime)
      }
    },
    stop = function(){
      self$process$kill()
      private$chrome$close()
    },
    is_alive = function(){
      self$process$is_alive()
    }
  ),
  private = list(
    chrome = NULL,
    Page = NULL,
    Runtime = NULL,
    client = NULL
  )
)

maybe_check <- function(check, private){
  if (check){
    sleep_while_shiny_busy(private$Runtime)
    check_still_running(private$Runtime)
  }
}
