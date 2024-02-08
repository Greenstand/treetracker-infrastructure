This is the parent directory of all Digital Ocean [cloud computing platform] environments.

Each sub-directory here is a [DitigalOcean region](https://docs.digitalocean.com/products/platform/availability-matrix/), with the exception of `global`, which includes environments that are not *region*-specific.

**IMPORTANT NOTE**
 - Existing resources exist in the SFO2 region, but this region is limited in use and should be moved away from.
   From [region availability matrix](https://docs.digitalocean.com/products/platform/availability-matrix/):
   ```
   Due to limited capacity in NYC2, AMS2, SFO1, and SFO2,
   only users who already have existing resources in those regions
   can create more resources there.
   ```
   SFO3 is the preferred new region over SFO2, as it supports the most new services.
