# ---- Country flags -----------------------------------------------------------
#
# Flags are resolved on demand from flagcdn.com (public-domain national flags)
# as `https://flagcdn.com/w<width>/<iso2>.png`.  Nothing is bundled with the
# package; `flag_cache()` can pre-download a set for offline use.

#' Look up ISO 3166-1 alpha-2 codes for country names
#'
#' Maps common English and German country names (case-insensitive) to their
#' lower-case ISO alpha-2 code.  Values already looking like a 2-letter code
#' are passed through.  Unknown names return `NA`.
#'
#' @param names Character vector of country names or ISO codes.
#' @return Character vector of lower-case ISO alpha-2 codes (or `NA`).
#' @examples
#' country_to_iso(c("China", "Deutschland", "United Kingdom", "gr"))
#' @export
country_to_iso <- function(names) {
  lut <- .country_iso_lut()
  key <- tolower(trimws(names))
  out <- unname(lut[key])
  # Pass through anything that already looks like an ISO2 code
  looks_iso <- is.na(out) & grepl("^[a-z]{2}$", key)
  out[looks_iso] <- key[looks_iso]
  out
}

#' URL of a flag PNG on flagcdn.com
#'
#' @param iso Character vector of ISO alpha-2 codes (see [country_to_iso()]).
#' @param width Pixel width of the served PNG (flagcdn offers 20-2560).
#'   Default `160`.
#' @return Character vector of URLs (`NA` where `iso` is `NA`).
#' @examples
#' flag_url(country_to_iso(c("China", "Norway")))
#' @export
flag_url <- function(iso, width = 160) {
  ifelse(is.na(iso), NA_character_,
         sprintf("https://flagcdn.com/w%d/%s.png", as.integer(width), iso))
}

#' Pre-download flags for offline use
#'
#' Downloads flag PNGs into a local directory and returns the file paths, so
#' plots can be rendered without network access.  Requires an internet
#' connection at download time.
#'
#' @param iso Character vector of ISO alpha-2 codes.
#' @param dir Destination directory.  Default: a per-session cache under
#'   [tempdir()].
#' @param width Pixel width to fetch.  Default `160`.
#' @param overwrite Re-download files that already exist?  Default `FALSE`.
#' @return Character vector of local file paths (`NA` where download failed).
#' @export
flag_cache <- function(iso, dir = file.path(tempdir(), "ggvmap-flags"),
                       width = 160, overwrite = FALSE) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  vapply(iso, function(code) {
    if (is.na(code)) return(NA_character_)
    dest <- file.path(dir, paste0(code, ".png"))
    if (file.exists(dest) && !overwrite) return(dest)
    ok <- tryCatch({
      utils::download.file(flag_url(code, width), dest, quiet = TRUE,
                           mode = "wb")
      file.exists(dest) && file.info(dest)$size > 0
    }, error = function(e) FALSE)
    if (isTRUE(ok)) dest else NA_character_
  }, character(1), USE.NAMES = FALSE)
}

#' Country name -> ISO alpha-2 lookup table
#' @noRd
.country_iso_lut <- function() {
  # English + German aliases -> ISO2 (lower case)
  pairs <- list(
    ad = c("andorra"),
    ae = c("united arab emirates", "uae", "vereinigte arabische emirate",
           "ver. arabische emirate"),
    ar = c("argentina", "argentinien"),
    at = c("austria", "\u00f6sterreich", "oesterreich"),
    au = c("australia", "australien"),
    bb = c("barbados"),
    be = c("belgium", "belgien"),
    bg = c("bulgaria", "bulgarien"),
    bh = c("bahrain"),
    bn = c("brunei"),
    br = c("brazil", "brasilien"),
    bs = c("bahamas"),
    ca = c("canada", "kanada"),
    cd = c("dr congo", "democratic republic of the congo",
           "dem. rep. kongo", "dem. rep. congo", "kongo"),
    ch = c("switzerland", "schweiz"),
    cl = c("chile"),
    cn = c("china"),
    co = c("colombia", "kolumbien"),
    cw = c("curacao", "cura\u00e7ao"),
    cy = c("cyprus", "zypern"),
    cz = c("czechia", "czech republic", "tschechien"),
    de = c("germany", "deutschland"),
    dk = c("denmark", "d\u00e4nemark", "daenemark"),
    dm = c("dominica"),
    ee = c("estonia", "estland"),
    eg = c("egypt", "\u00e4gypten", "aegypten"),
    es = c("spain", "spanien"),
    fi = c("finland", "finnland"),
    fo = c("faroe islands", "f\u00e4r\u00f6er", "faeroeer"),
    fr = c("france", "frankreich"),
    gb = c("united kingdom", "uk", "great britain", "britain",
           "gro\u00dfbritannien", "grossbritannien", "vereinigtes k\u00f6nigreich"),
    gi = c("gibraltar"),
    gr = c("greece", "griechenland"),
    hk = c("hong kong", "hongkong"),
    hr = c("croatia", "kroatien"),
    hu = c("hungary", "ungarn"),
    id = c("indonesia", "indonesien"),
    ie = c("ireland", "irland"),
    il = c("israel"),
    "in" = c("india", "indien"),
    is = c("iceland", "island"),
    it = c("italy", "italien"),
    jp = c("japan"),
    ke = c("kenya", "kenia"),
    kr = c("south korea", "korea", "s\u00fcdkorea", "suedkorea"),
    kw = c("kuwait"),
    li = c("liechtenstein"),
    lr = c("liberia"),
    lt = c("lithuania", "litauen"),
    lu = c("luxembourg", "luxemburg"),
    lv = c("latvia", "lettland"),
    ma = c("morocco", "marokko"),
    mh = c("marshall islands", "marshallinseln"),
    mo = c("macau", "macao"),
    mt = c("malta"),
    mu = c("mauritius"),
    mx = c("mexico", "mexiko"),
    my = c("malaysia"),
    ng = c("nigeria"),
    nl = c("netherlands", "niederlande", "holland"),
    no = c("norway", "norwegen"),
    nz = c("new zealand", "neuseeland"),
    om = c("oman"),
    pa = c("panama"),
    pe = c("peru"),
    pf = c("french polynesia", "franz\u00f6sisch-polynesien",
           "franzoesisch-polynesien"),
    ph = c("philippines", "philippinen"),
    pl = c("poland", "polen"),
    pt = c("portugal"),
    qa = c("qatar", "katar"),
    ro = c("romania", "rum\u00e4nien", "rumaenien"),
    rs = c("serbia", "serbien"),
    ru = c("russia", "russland"),
    sa = c("saudi arabia", "saudi-arabien", "saudi arabien"),
    sc = c("seychelles", "seychellen"),
    se = c("sweden", "schweden"),
    sg = c("singapore", "singapur"),
    si = c("slovenia", "slowenien"),
    sk = c("slovakia", "slowakei"),
    sm = c("san marino"),
    sx = c("sint maarten"),
    th = c("thailand"),
    tr = c("turkey", "t\u00fcrkei", "tuerkei", "turkiye"),
    tw = c("taiwan"),
    ua = c("ukraine"),
    us = c("united states", "usa", "united states of america",
           "vereinigte staaten"),
    vn = c("vietnam"),
    xk = c("kosovo"),
    za = c("south africa", "s\u00fcdafrika", "suedafrika")
  )
  iso  <- rep(names(pairs), lengths(pairs))
  name <- unlist(pairs, use.names = FALSE)
  stats::setNames(iso, name)
}
