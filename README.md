
<!-- README.md is generated from README.Rmd. Please edit that file -->
cowsquito: Identifying geographical areas of greatest potential impact for livestock ivermectin implants
========================================================================================================

Data sources
============

### Where are the cows?

<https://livestock.geo-wiki.org/Application/index.php>

### Where are the mosquitoes?

<https://map.ox.ac.uk/explorer/#/explorer>

Methods
=======

-   We use raw raster data on where cattle are from the International Livestock Research Institute (ILRI) and the Food and Agriculture Organization of the United Nations (FAO) and the Université Libre de Bruxelles (ULB-LUBIES).
-   We use raw raster data on the Plasmodium falciparum parasite rate in 2-10 year olds in Africa in 2015, made available through the Malaria Atlas Project.
-   We use R to process the data, standardize their geographic attributes (extents, projections) and quality attributes (granularity, etc.).
-   We use simple percentilization to scale incidence (0-1) and cattle per square kilometer (0-Inf) into a 0-100 metric.
-   We combine our two metrics by simple average. So, in the combined score, 0 means no Pf or cattle, and 100 means the maximum amount of Pf and cattle. Anything between the two represents some combination. This method assumes an equilinear value of both percentilized Pf and cattle (ie, a place with 60th percentile cattle density and 40th percentile Pf is equally as promising as a place with 40th percentile cattle density and 60th percentile Pf).
-   Full code in this repo (`code.R`).

Results
=======

Malaria prevalence on the Plasmodium falciparum parasite rate in 2-10 year-olds.
--------------------------------------------------------------------------------

The below shows the raw data on the Plasmodium falciparum parasite rate in 2-10 year-olds.

<img src="README-unnamed-chunk-3-1.png" style="display: block; margin: auto;" />

The below shows our (scaled) data on the Plasmodium falciparum parasite rate in 2-10 year-olds.

<img src="README-unnamed-chunk-4-1.png" style="display: block; margin: auto;" />

Cattle density
--------------

The below shows the raw data on cattle density per square kilometer.

<img src="README-unnamed-chunk-5-1.png" style="display: block; margin: auto;" />

The below shows our (scaled) cattle scores (Africa only).

<img src="README-unnamed-chunk-6-1.png" style="display: block; margin: auto;" />

Combined score
--------------

The below shows our combined score.

<img src="README-unnamed-chunk-7-1.png" style="display: block; margin: auto;" />

Discussion
==========

West Africa appears to be the region with the most promise for ivermectin-infused cows. Yummy.

Contact
=======

[Databrew](http://www.databrew.cc), empowering researchers in academia and industry to explore, understand, and communicate their data through consulting and teaching. <a href="mailto:info@databrew.cc?Subject=Hello" target="_top">info@databrew.cc</a>.

<img align="center" src="logo_clear.png" alt="http://databrew.cc">
