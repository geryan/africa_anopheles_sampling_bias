make_flat_mask <- function(r){

  r[which(!is.na(values(r)))] <- 1

  r

}
