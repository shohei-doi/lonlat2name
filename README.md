lonlat2name ver 0.1
================

Rで緯度経度を都道府県名あるいは市区町村名に変換する関数`lonlat2name()`を書きました。

  - 作成者：土井翔平
  - 連絡先：<shohei.doi0504@gmail.com>

基本的には[nozmaさんの記事](https://qiita.com/nozma/items/808bce2f496eabd50ff1)と[uriさんの記事](https://qiita.com/uri/items/69b2c05f7b3a21d3aad3)を参考にしています。

主な改善点は

  - 入力引数としてベクトルを取るようにした
  - ループする際に並列化可能にした

ことです（そもそもの動機は上記コードではうまく行かない場合があったからです）。

なお、現時点では日本しか対応していませんが、任意の国の行政区域に関するシェープファイルがあれば適当にコードを書き直せがうまく行くはずです。

## 更新履歴

  - 2019年9月10日：ver
0.1を公開しました。

## 依存パッケージ

`lonlat2name()`は以下のパッケージに依存しています。

  - `sf`

データフレームとして出力する場合は以下のパッケージにも依存しています。

  - `tibble`

また、並列化させる場合は以下のパッケージにも依存しています。

  - `pforeach`

# 使い方

## 読み込み

`wareki2seireki.R`を適当なディレクトリに保存して、`source()`で読み込むか、

``` r
source("lonlat2name.R")
```

    ## Linking to GEOS 3.6.2, GDAL 2.2.3, PROJ 4.9.3

    ## Loading required package: tibble

    ## Loading required package: pforeach

オンライン環境であれば、URLを入力して直接読み込むことができます。

``` r
source("https://raw.githubusercontent.com/shohei-doi/lonlat2name/master/lonlat2name.R")
```

また、[国土地理院のサイト](http://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-N03-v2_3.html)からシェープファイルをダウンロードし、**フォルダごと**適当なディレクトリに保存して（今回は作業ディレクトリの下の`japan_map`という名前のディレクトリとします）、その中の`N03-19_190101.shp`を読み込みます。

``` r
japan <- st_read("japan_map/N03-19_190101.shp")
```

    ## Reading layer `N03-19_190101' from data source `/home/shohei/Dropbox/package/lonlat2name/japan_map/N03-19_190101.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 117580 features and 5 fields
    ## geometry type:  POLYGON
    ## dimension:      XY
    ## bbox:           xmin: 122.9337 ymin: 20.42275 xmax: 153.9868 ymax: 45.55724
    ## epsg (SRID):    NA
    ## proj4string:    +proj=longlat +ellps=GRS80 +no_defs

## 動作

### 基本操作

第1引数に**経度**、第2引数に**緯度**、第3引数に先程読み込んだシェープファイルを取ります。

``` r
lonlat2name(135, 35, shape = japan)
```

    ## [1] "兵庫県"

デフォルトでは都道府県名ですが、`target`に`city`を取ると市区町村名を出します。

``` r
lonlat2name(135, 35, shape = japan, target = "city")
```

    ## [1] "西脇市"

`both`とすると両方を出力します。

``` r
lonlat2name(135, 35, shape = japan, target = "both")
```

    ## [1] "兵庫県西脇市"

`code`とすると行政区域コードを返します。

``` r
lonlat2name(135, 35, shape = japan, target = "code")
```

    ## [1] 1303

`df`とすると緯度経度、都道府県名と市区町村名、行政区域コードを変数とするデータフレームを返します。

``` r
lonlat2name(135, 35, shape = japan, target = "df")
```

    ## # A tibble: 1 x 5
    ##     lon   lat prefecture city    code
    ##   <dbl> <dbl> <chr>      <chr>  <dbl>
    ## 1   135    35 兵庫県     西脇市  1303

緯度経度のどちらかが欠損値の場合は欠損値を返します。

``` r
lonlat2name(135, NA, shape = japan)
```

    ## [1] NA

日本国外の場合は`国外`と返します。

``` r
lonlat2name(150, 35, shape = japan)
```

    ## [1] "国外"

また、オプションで`remove_out =
TRUE`とすると、[日本の東西南北端点の緯度経度](https://www.gsi.go.jp/KOKUJYOHO/center.htm)の中に入っていないものは`国外`と返します。

  - 検索しなくていいので若干速度が上がります。

<!-- end list -->

``` r
lonlat2name(100, 100, shape = japan, remove_out = TRUE)
```

    ## [1] "国外"

### ベクトル

入力引数をベクトルとすることもできます。

  - 現時点ではループを使っているので、かなり遅いです……

<!-- end list -->

``` r
lon <- c(139.767125, 135.762125, 132.453592)
lat <- c(35.681236, 35.025414, 34.395483)
lonlat2name(lon, lat, shape = japan, target = "df")
```

    ## # A tibble: 3 x 5
    ##     lon   lat prefecture city          code
    ##   <dbl> <dbl> <chr>      <chr>        <dbl>
    ## 1  140.  35.7 東京都     千代田区       661
    ## 2  136.  35.0 京都府     京都市上京区  1176
    ## 3  132.  34.4 広島県     広島市中区    1469

したがって、`mutate()`の中で使用することもできます。

``` r
library(tidyverse)
```

    ## ── Attaching packages ─────────────────────────────────────────────────────────────────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.2.1     ✔ purrr   0.3.2
    ## ✔ tidyr   0.8.3     ✔ dplyr   0.8.3
    ## ✔ readr   1.3.1     ✔ stringr 1.4.0
    ## ✔ ggplot2 3.2.1     ✔ forcats 0.4.0

    ## ── Conflicts ────────────────────────────────────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ readr::cols()   masks pforeach::cols()
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

``` r
tibble(lon, lat) %>% 
  mutate(prefecture = lonlat2name(lon, lat, shape = japan, target = "prefecture"))
```

    ## # A tibble: 3 x 3
    ##     lon   lat prefecture
    ##   <dbl> <dbl> <chr>     
    ## 1  140.  35.7 東京都    
    ## 2  136.  35.0 京都府    
    ## 3  132.  34.4 広島県

複数の情報を追加する場合は次のように書くのがいいかと思います。

``` r
tibble(lon, lat) %>% 
  mutate(id = row_number()) %>%  #もしIDに相当する変数がない場合
  group_by(id) %>% 
  nest() %>% 
  mutate(location = data %>% 
           map(~lonlat2name(.$lon, .$lat, shape = japan, target = "df"))) %>% 
  unnest()
```

    ## # A tibble: 3 x 8
    ##      id   lon   lat  lon1  lat1 prefecture city          code
    ##   <int> <dbl> <dbl> <dbl> <dbl> <chr>      <chr>        <dbl>
    ## 1     1  140.  35.7  140.  35.7 東京都     千代田区       661
    ## 2     2  136.  35.0  136.  35.0 京都府     京都市上京区  1176
    ## 3     3  132.  34.4  132.  34.4 広島県     広島市中区    1469

`parallel = TRUE`とすることで並列化により、実行速度が早くなるかもしれません。

``` r
lonlat2name(lon, lat, shape = japan, target = "df", parallel = TRUE)
```

    ## 
    ## Attaching package: 'lubridate'

    ## The following object is masked from 'package:base':
    ## 
    ##     date

    ## 
    ## Attaching package: 'assertthat'

    ## The following object is masked from 'package:tibble':
    ## 
    ##     has_name

    ## 
    ## Attaching package: 'foreach'

    ## The following objects are masked from 'package:purrr':
    ## 
    ##     accumulate, when

    ## 
    ## Attaching package: 'evaluate'

    ## The following object is masked from 'package:assertthat':
    ## 
    ##     is.error

    ## 
    ## Attaching package: 'pillar'

    ## The following object is masked from 'package:dplyr':
    ## 
    ##     dim_desc

    ## 
    ## Attaching package: 'rlang'

    ## The following object is masked from 'package:assertthat':
    ## 
    ##     has_name

    ## The following objects are masked from 'package:purrr':
    ## 
    ##     %@%, as_function, flatten, flatten_chr, flatten_dbl,
    ##     flatten_int, flatten_lgl, flatten_raw, invoke, list_along,
    ##     modify, prepend, splice

    ## 
    ## Attaching package: 'lazyeval'

    ## The following objects are masked from 'package:rlang':
    ## 
    ##     as_name, call_modify, call_standardise, expr_label, expr_text,
    ##     f_env, f_env<-, f_label, f_lhs, f_lhs<-, f_rhs, f_rhs<-,
    ##     f_text, is_atomic, is_call, is_formula, is_lang, is_pairlist,
    ##     missing_arg

    ## The following objects are masked from 'package:purrr':
    ## 
    ##     is_atomic, is_formula

    ## 
    ## Attaching package: 'modelr'

    ## The following object is masked from 'package:broom':
    ## 
    ##     bootstrap

    ## 
    ## Attaching package: 'xfun'

    ## The following objects are masked from 'package:base':
    ## 
    ##     attr, isFALSE

    ## 
    ## Attaching package: 'pkgconfig'

    ## The following object is masked from 'package:httr':
    ## 
    ##     set_config

    ## Loading required package: registry

    ## 
    ## Attaching package: 'pkgmaker'

    ## The following object is masked from 'package:xfun':
    ## 
    ##     isFALSE

    ## The following object is masked from 'package:assertthat':
    ## 
    ##     is.dir

    ## The following object is masked from 'package:base':
    ## 
    ##     isFALSE

    ## 
    ## Attaching package: 'crayon'

    ## The following object is masked from 'package:rlang':
    ## 
    ##     chr

    ## The following object is masked from 'package:ggplot2':
    ## 
    ##     %+%

    ## 
    ## Attaching package: 'withr'

    ## The following object is masked from 'package:rlang':
    ## 
    ##     with_options

    ## 
    ## Attaching package: 'nlme'

    ## The following object is masked from 'package:dplyr':
    ## 
    ##     collapse

    ## 
    ## Attaching package: 'jsonlite'

    ## The following objects are masked from 'package:rlang':
    ## 
    ##     flatten, unbox

    ## The following object is masked from 'package:purrr':
    ## 
    ##     flatten

    ## 
    ## Attaching package: 'magrittr'

    ## The following object is masked from 'package:rlang':
    ## 
    ##     set_names

    ## The following object is masked from 'package:purrr':
    ## 
    ##     set_names

    ## The following object is masked from 'package:tidyr':
    ## 
    ##     extract

    ## udunits system database from /usr/share/xml/udunits

    ## 
    ## Attaching package: 'scales'

    ## The following object is masked from 'package:purrr':
    ## 
    ##     discard

    ## The following object is masked from 'package:readr':
    ## 
    ##     col_factor

    ## KernSmooth 2.23 loaded
    ## Copyright M. P. Wand 1997-2009

    ## 
    ## Attaching package: 'cli'

    ## The following object is masked from 'package:pillar':
    ## 
    ##     style_bold

    ## Loading required package: rngtools

    ## Loading required package: iterators

    ## Loading required package: parallel

    ## 
    ## Attaching package: 'xml2'

    ## The following object is masked from 'package:rlang':
    ## 
    ##     as_list

    ## 
    ## Attaching package: 'generics'

    ## The following object is masked from 'package:compiler':
    ## 
    ##     compile

    ## The following object is masked from 'package:e1071':
    ## 
    ##     interpolate

    ## The following object is masked from 'package:evaluate':
    ## 
    ##     evaluate

    ## The following objects are masked from 'package:lubridate':
    ## 
    ##     as.difftime, intersect, setdiff, union

    ## The following objects are masked from 'package:dplyr':
    ## 
    ##     explain, intersect, setdiff, setequal, union

    ## The following objects are masked from 'package:base':
    ## 
    ##     as.difftime, as.factor, as.ordered, intersect, is.element,
    ##     setdiff, setequal, union

    ## 
    ## Attaching package: 'vctrs'

    ## The following object is masked from 'package:lubridate':
    ## 
    ##     new_duration

    ## 
    ## Attaching package: 'tools'

    ## The following objects are masked from 'package:xfun':
    ## 
    ##     file_ext, Rcmd

    ## 
    ## Attaching package: 'glue'

    ## The following object is masked from 'package:nlme':
    ## 
    ##     collapse

    ## The following object is masked from 'package:dplyr':
    ## 
    ##     collapse

    ## 
    ## Attaching package: 'hms'

    ## The following object is masked from 'package:lubridate':
    ## 
    ##     hms

    ## 
    ## Attaching package: 'colorspace'

    ## The following object is masked from 'package:munsell':
    ## 
    ##     desaturate

    ## 
    ## Attaching package: 'rvest'

    ## The following object is masked from 'package:purrr':
    ## 
    ##     pluck

    ## The following object is masked from 'package:readr':
    ## 
    ##     guess_encoding

    ## # A tibble: 3 x 5
    ##     lon   lat prefecture city          code
    ##   <dbl> <dbl> <chr>      <chr>        <dbl>
    ## 1  140.  35.7 東京都     千代田区       661
    ## 2  136.  35.0 京都府     京都市上京区  1176
    ## 3  132.  34.4 広島県     広島市中区    1469

ちなみに、`{jpndistrict}`というパッケージの中にはこのようなデータが含まれていて、便利です。

``` r
jpndistrict::jpnprefs
```

    ## # A tibble: 47 x 11
    ##    jis_code prefecture capital region major_island prefecture_en capital_en
    ##    <chr>    <chr>      <chr>   <chr>  <chr>        <chr>         <chr>     
    ##  1 01       北海道     札幌市  北海道 北海道       Hokkaido      Sapporo-s…
    ##  2 02       青森県     青森市  東北   本州         Aomori-ken    Aomori-shi
    ##  3 03       岩手県     盛岡市  東北   本州         Iwate-ken     Morioka-s…
    ##  4 04       宮城県     仙台市  東北   本州         Miyagi-ken    Sendai-shi
    ##  5 05       秋田県     秋田市  東北   本州         Akita-ken     Akita-shi 
    ##  6 06       山形県     山形市  東北   本州         Yamagata-ken  Yamagata-…
    ##  7 07       福島県     福島市  東北   本州         Fukushima-ken Fukushima…
    ##  8 08       茨城県     水戸市  関東   本州         Ibaraki-ken   Mito-shi  
    ##  9 09       栃木県     宇都宮市… 関東   本州         Tochigi-ken   Utsunomiy…
    ## 10 10       群馬県     前橋市  関東   本州         Gunma-ken     Maebashi-…
    ## # … with 37 more rows, and 4 more variables: region_en <chr>,
    ## #   major_island_en <chr>, capital_latitude <dbl>, capital_longitude <dbl>

## セッション情報

``` r
sessionInfo()
```

    ## R version 3.6.1 (2019-07-05)
    ## Platform: x86_64-pc-linux-gnu (64-bit)
    ## Running under: Ubuntu 18.04.3 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.7.1
    ## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.7.1
    ## 
    ## locale:
    ##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
    ##  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
    ##  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
    ##  [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
    ##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
    ## [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
    ## 
    ## attached base packages:
    ##  [1] tools     parallel  grid      compiler  stats     graphics  grDevices
    ##  [8] utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ##  [1] haven_2.1.1        knitr_1.24         classInt_0.4-1    
    ##  [4] rvest_0.3.4        colorspace_1.4-1   yaml_2.2.0        
    ##  [7] hms_0.5.1          glue_1.3.1         vctrs_0.2.0       
    ## [10] generics_0.0.2     xml2_1.2.2         doParallel_1.0.15 
    ## [13] iterators_1.0.12   doRNG_1.7.1        rngtools_1.4      
    ## [16] stringi_1.4.3      cli_1.1.0          KernSmooth_2.23-15
    ## [19] bibtex_0.4.2       scales_1.0.0       units_0.6-4       
    ## [22] magrittr_1.5       DBI_1.0.0          gtable_0.3.0      
    ## [25] xtable_1.8-4       jsonlite_1.6       nlme_3.1-141      
    ## [28] withr_2.1.2        crayon_1.3.4       fansi_0.4.0       
    ## [31] codetools_0.2-16   tidyselect_0.2.5   htmltools_0.3.6   
    ## [34] pkgmaker_0.27      registry_0.5-1     pkgconfig_2.0.2   
    ## [37] xfun_0.9           modelr_0.1.5       broom_0.5.2       
    ## [40] munsell_0.5.0      rmarkdown_1.15     rstudioapi_0.10   
    ## [43] lazyeval_0.2.2     readxl_1.3.1       rlang_0.4.0       
    ## [46] pillar_1.4.2       httr_1.4.1         e1071_1.7-2       
    ## [49] evaluate_0.14      backports_1.1.4    R6_2.4.0          
    ## [52] cellranger_1.1.0   utf8_1.1.4         foreach_1.4.7     
    ## [55] digest_0.6.20      zeallot_0.1.0      assertthat_0.2.1  
    ## [58] class_7.3-15       lattice_0.20-38    lubridate_1.7.4   
    ## [61] Rcpp_1.0.2         forcats_0.4.0      stringr_1.4.0     
    ## [64] dplyr_0.8.3        purrr_0.3.2        readr_1.3.1       
    ## [67] tidyr_0.8.3        ggplot2_3.2.1      tidyverse_1.2.1   
    ## [70] pforeach_1.3       tibble_2.1.3       sf_0.7-7          
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] shiny_1.3.2       promises_1.0.1    httpuv_1.5.1     
    ##  [4] jpmesh_1.1.3      jpndistrict_0.3.4 later_0.8.0      
    ##  [7] mime_0.7          htmlwidgets_1.3   miniUI_0.1.1.1   
    ## [10] crosstalk_1.0.0   leaflet_2.0.2
