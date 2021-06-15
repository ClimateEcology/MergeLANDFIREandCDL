#!/bin/sh

module load gdal
module load proj
module load udunits
module load r
Rscript --vanilla -e 'install.packages("sf",  repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0",
configure.args=stringr::str_interp("--with-proj-include=/apps/proj-7.1.0/include --with-proj-lib=/apps/proj-7.1.0/lib --with-udunits2-lib=/apps/udunits-2.2.26/lib"))'


Sys.setenv(PROJ_LIB = "/apps/proj-7.1.0/include", UDUNITS2_LIBS="/apps/udunits-2.2.26/lib", UDUNITS2_INCLUDE="/apps/udunits-2.2.26/include")
install.packages("units",  repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0")






































install.packages("sf",  repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0")

# OR 

install.packages("sf", repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-lib=/apps/proj-7.1.0/share/proj"))
 # OR
install.packages("sf", repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-share=/apps/proj-7.1.0/share/proj"))


install.packages("sf", repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-include=/apps/proj-7.1.0/include --with-proj-lib=/apps/proj-7.1.0/include"))

# this approach fixes the 'cannot find proj.db' problem but then we run into 'cannot find proj.h' file. Ugh.
install.packages("sf", repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-share=/apps/proj-7.1.0/share/proj --with-proj-include=/apps/proj-7.1.0/include --with-proj-lib=/apps/proj-7.1.0/include"))






install.packages("sf", repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0") #, configure.args=stringr::str_interp("--with-proj-include=/apps/proj-7.1.0/include --with-proj-lib=/apps/proj-7.1.0/include"))

install.packages("sf", repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-include=/apps/proj-7.1.0/include --with-proj-lib=/apps/proj-7.1.0/share/proj"))
install.packages("sf", repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-include=/apps/proj-7.1.0/include --with-proj-lib=/apps/proj-7.1.0/share/proj"))
install.packages("sf", repos="http://cran.us.r-project.org", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-include=/apps/proj-7.1.0/include --with-proj-share=/apps/proj-7.1.0/share/proj"))








devtools::install_github("r-spatial/sf", lib="/project/geoecoservices/R_packages/4.0")
devtools::install_github("r-spatial/sf", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-share=/apps/proj-7.1.0/share/proj"))
devtools::install_github("r-spatial/sf", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-share=/apps/proj-7.1.0/share"))
devtools::install_github("r-spatial/sf", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-include=/apps/proj-7.1.0/include --with-proj-lib=/apps/proj-7.1.0/include --with-proj-share=/apps/proj-7.1.0/share/proj"))
devtools::install_github("r-spatial/sf", lib="/project/geoecoservices/R_packages/4.0", configure.args=stringr::str_interp("--with-proj-include=/apps/proj-7.1.0/include --with-proj-share=/apps/proj-7.1.0/share/proj"))

