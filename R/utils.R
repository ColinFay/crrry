maybe_check <- function(check, private){
  if (check){
    sleep_while_shiny_busy(private$Runtime)
    check_still_running(private$Runtime)
  }
}
