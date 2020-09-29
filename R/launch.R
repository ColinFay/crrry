#' @title Generic crrry methods
CrrryGeneric <- R6::R6Class(
  "CrrryGeneric",
  public = list(
    #' @field process Chrome process, frm `{crrri}`
    process = NULL,
    #' @description
    #' Execute JavaScript code in the session.
    #' @param code JS code
    #' @param check Should `{crrry}` check if Shiny is still running?
    call_js = function(code, check = TRUE){
      cli::cat_rule(
        sprintf("Launching JS: %s", code)
      )
      crrri::hold({
        private$Runtime$evaluate(
          expression = code
        )
      })
      maybe_check(check, private)
    },
    #' @description
    #' Click on an id
    #' @param id ID
    #' @param check Should `{crrry}` check if Shiny is still running?
    click_on_id = function(id, check = TRUE){
      cli::cat_rule(
        sprintf("Clicking on id: %s", id)
      )
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
    #' @description
    #' Send a `gremlin.js` horde
    #' @param check Should `{crrry}` check if Shiny is still running?
    gremlins_horde = function(check = TRUE){
      cli::cat_rule(
        "Sending hordes of gremlins"
      )
      # https://github.com/marmelab/gremlins.js
      crrri::hold({
        private$Runtime$evaluate(
          expression = '(function() {
            function callback() {
                gremlins.createHorde({
                    species: [gremlins.species.clicker(),gremlins.species.toucher(),gremlins.species.formFiller(),gremlins.species.scroller(),gremlins.species.typer()],
                    mogwais: [gremlins.mogwais.alert(),gremlins.mogwais.fps(),gremlins.mogwais.gizmo()],
                    strategies: [gremlins.strategies.distribution()]
                }).unleash();
            }
            var s = document.createElement("script");
            s.src = "https://unpkg.com/gremlins.js";
            if (s.addEventListener) {
                s.addEventListener("load", callback, false);
            } else if (s.readyState) {
                s.onreadystatechange = callback;
            }
            document.body.appendChild(s);
            })()'
        )
      })
      maybe_check(check, private)
    },
    #' @description
    #' Set the value of a shiny input
    #' @param id Shiny ID
    #' @param val Value for the ID
    #' @param check Should `{crrry}` check if Shiny is still running?
    shiny_set_input = function(id, val, check = TRUE){
      cli::cat_rule(
        sprintf("Setting id %s with value %s", id, val)
      )
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
    #' @description
    #' Wait for Shiny to be ready
    #' @param check Should `{crrry}` check if Shiny is still running?
    wait_for_shiny_ready = function(check = TRUE){
      sleep_while_shiny_busy(private$Runtime)
      if(check){
        check_still_running(private$Runtime)
      }
    },
    #' @description
    #' Wait for a JS condition to be TRUE
    #' @param cond JS condition
    #' @param check Should `{crrry}` check if Shiny is still running?
    wait_for = function(cond, check = TRUE){
      sleep_while(cond, private$Runtime)
      if(check){
        check_still_running(private$Runtime)
      }
    }
  ),
  private = list(
    chrome = NULL,
    Page = NULL,
    Runtime = NULL,
    client = NULL
  )
)

#' @title Launch a crrrry on a webpage
#'
#' @return A crrrry object
#'
#' @export
CrrryOnPage <- R6::R6Class(
  "CrrryOnPage",
  inherit = CrrryGeneric,
  public = list(
    #' @description
    #' Create a Chrome object that connect to an URL with a Shiny App
    #' @param chrome_bin Path to Chrome binary, passed to `Chrome$new()`
    #' @param url URL where the app is running
    #' @param chrome_port Chrome_port, passed to `Chrome$new()`
    #' @param headless Run headless? Passed to `Chrome$new()`
    #' @param ... Futher args passed to `Chrome$new()`
    initialize = function(
      chrome_bin = Sys.getenv("HEADLESS_CHROME"),
      chrome_port = 9222L,
      url,
      headless = headless,
      ...
    ){
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
          url = url
        )
      })
    },
    #' @description
    #' Stop the process
    stop = function(){
      private$chrome$close()
    },
    #' @description
    #' Check if the url is available
    is_alive = function(){
      attr( curlGetHeaders(url), "status" ) == 200
    }
  )
)


#' @title Launch a crrrry on a local process
#'
#' @return A crrrry object
#'
#' @export
CrrryProc <- R6::R6Class(
  "CrrryOnPage",
  inherit = CrrryGeneric,
  public = list(
    #' @description
    #' Wait for a JS condition to be TRUE
    #' @param chrome_bin Path to Chrome binary, passed to `Chrome$new()`
    #' @param fun A function launching the shiny app
    #' @param shiny_port The port to launch the shiny apps on
    #' @param chrome_port Chrome_port, passed to `Chrome$new()`
    #' @param headless Run headless? Passed to `Chrome$new()`
    #' @param ... Futher args passed to `Chrome$new()`
    initialize = function(
      chrome_bin = Sys.getenv("HEADLESS_CHROME"),
      fun = "pkgload::load_all();run_app()",
      shiny_port = 2811L,
      chrome_port = 9222L,
      headless = TRUE,
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
        headless = headless,
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

    },
    #' @description
    #' Stop the process
    stop = function(){
      self$process$kill()
      private$chrome$close()
    },
    #' @description
    #' Check if the url is available
    is_alive = function(){
      self$process$is_alive()
    }
  )
)
