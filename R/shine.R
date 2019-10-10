sleep_while_shiny_busy <- function(Runtime, timeout = 1){
  cli::cat_line("Shiny is computing")
  repeat {
    #browser()
    res <- Runtime$evaluate(
      expression = 'document.getElementsByTagName("html").className == "shiny-busy" && document.getElementById("shiny-disconnected-overlay") == null'
    )
    res <- crrri::hold(res)
    if (!is.null(res$result$value) && !res$result$value){
      print("break")
      break()
    }
    Sys.sleep(timeout)
  }
}

check_still_running <- function(Runtime){
  res <- Runtime$evaluate(
    expression = 'document.getElementById("shiny-disconnected-overlay") !== null'
  )
  res <- crrri::hold(res)
  if (!is.null(res$result$value) && res$result$value){
    stop("Shiny stopped working")
  } else {
    cli::cat_bullet("Shiny is still running", bullet_col = "green", bullet = "tick")
  }
}
