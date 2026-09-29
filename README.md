
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fstpindia

<!-- badges: start -->

[![License: CC BY
4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![R-CMD-check](https://github.com/agentsforsci-ghe/fstp-eval-india/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/agentsforsci-ghe/fstp-eval-india/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

The goal of fstpindia is to provide the data of the report *Evaluation
of FSTPs and STP Co-treatment Systems across India* by the Centre for
Science and Environment (CSE), New Delhi, 2023, as tidy datasets in R
and as CSV and XLSX files. The report evaluated 69 faecal sludge
treatment plants (FSTPs) and sewage treatment plants (STPs) with
co-treatment of faecal sludge in eight Indian states.

## Installation

You can install the development version of fstpindia from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("agentsforsci-ghe/fstp-eval-india")
```

``` r
## Run the following code in console if you don't have the packages
## install.packages(c("dplyr", "knitr", "readr", "stringr", "kableExtra"))
library(dplyr)
library(knitr)
library(readr)
library(stringr)
library(kableExtra)
```

Alternatively, you can download the individual datasets as a CSV or XLSX
file from the table below.

1.  Click Download CSV. A window opens that displays the CSV in your
    browser.
2.  Right-click anywhere inside the window and select “Save Page As…”.
3.  Save the file in a folder of your choice.

| dataset | CSV | XLSX |
|:---|:---|:---|
| bod_compliance | [Download CSV](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/bod_compliance.csv) | [Download XLSX](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/bod_compliance.xlsx) |
| fstp_performance | [Download CSV](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/fstp_performance.csv) | [Download XLSX](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/fstp_performance.xlsx) |
| plants | [Download CSV](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/plants.csv) | [Download XLSX](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/plants.xlsx) |
| removal_stages | [Download CSV](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/removal_stages.csv) | [Download XLSX](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/removal_stages.xlsx) |
| samples | [Download CSV](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/samples.csv) | [Download XLSX](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/samples.xlsx) |
| sludge_characteristics | [Download CSV](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/sludge_characteristics.csv) | [Download XLSX](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/sludge_characteristics.xlsx) |
| stp_performance | [Download CSV](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/stp_performance.csv) | [Download XLSX](https://github.com/agentsforsci-ghe/fstp-eval-india/raw/main/inst/extdata/stp_performance.xlsx) |

## Data

The package provides access to …

``` r
library(fstpindia)
```

### bod_compliance

The dataset `bod_compliance` contains data about … It has 69
observations and 7 variables

``` r
bod_compliance |> 
  head(3) |> 
  knitr::kable()
```

| plant_id | plant | state | plant_type | technology | bod_summary_mgl | bod_annex_mgl |
|:---|:---|:---|:---|:---|---:|---:|
| tg-siddipet | Siddipet | Telangana | FSTP | DEWATS | 6.3 | 6.3 |
| tg-sircilla | Sircilla | Telangana | FSTP | DEWATS | 24.0 | 24.0 |
| tn-thirumangalam | Thirumangalam | Tamil Nadu | FSTP | DEWATS | 16.3 | 16.3 |

For an overview of the variable names, see the following table.

<div style="border: 1px solid #ddd; padding: 0px; overflow-y: scroll; height:200px; ">

<table class="table table-striped" style="margin-left: auto; margin-right: auto;">

<thead>

<tr>

<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">

variable_name
</th>

<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">

variable_type
</th>

<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">

description
</th>

</tr>

</thead>

<tbody>

<tr>

<td style="text-align:left;">

plant_id
</td>

<td style="text-align:left;">

character
</td>

<td style="text-align:left;">

NA
</td>

</tr>

<tr>

<td style="text-align:left;">

plant
</td>

<td style="text-align:left;">

character
</td>

<td style="text-align:left;">

NA
</td>

</tr>

<tr>

<td style="text-align:left;">

state
</td>

<td style="text-align:left;">

character
</td>

<td style="text-align:left;">

NA
</td>

</tr>

<tr>

<td style="text-align:left;">

plant_type
</td>

<td style="text-align:left;">

character
</td>

<td style="text-align:left;">

NA
</td>

</tr>

<tr>

<td style="text-align:left;">

technology
</td>

<td style="text-align:left;">

character
</td>

<td style="text-align:left;">

NA
</td>

</tr>

<tr>

<td style="text-align:left;">

bod_summary_mgl
</td>

<td style="text-align:left;">

numeric
</td>

<td style="text-align:left;">

NA
</td>

</tr>

<tr>

<td style="text-align:left;">

bod_annex_mgl
</td>

<td style="text-align:left;">

numeric
</td>

<td style="text-align:left;">

NA
</td>

</tr>

</tbody>

</table>

</div>

## Example

Describe here what the plot below shows and why it is a useful first
look at the data.

``` r
library(fstpindia)
# install.packages("ggplot2")
# library(ggplot2)

# A first plot of the data: replace the aesthetics with variables from
# bod_compliance, then uncomment the block and the library call above.
# bod_compliance |>
#   ggplot(aes(x = , y = )) +
#   geom_point() +
#   labs(x = "", y = "", title = "")
```

## License

Data are available as
[CC-BY](https://github.com/agentsforsci-ghe/fstp-eval-india/blob/main/LICENSE.md).

## Citation

Please cite this package using:

``` r
citation("fstpindia")
#> To cite package 'fstpindia' in publications use:
#> 
#>   Schöbitz L (????). _fstpindia: Performance of Faecal Sludge and
#>   Co-Treatment Plants in India_. R package version 0.0.0.9000.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {fstpindia: Performance of Faecal Sludge and Co-Treatment Plants in India},
#>     author = {Lars Schöbitz},
#>     note = {R package version 0.0.0.9000},
#>   }
```
