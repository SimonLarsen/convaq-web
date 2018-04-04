FROM r-base:3.4.3
MAINTAINER Simon J. Larsen "simonhffh@gmail.com"

EXPOSE 3838

RUN apt-get update && apt-get install -y gdebi-core libssl-dev libxml2-dev libcurl4-gnutls-dev libnlopt-dev libnlopt0 texlive texlive-latex-extra libmariadb-dev

RUN R -e "install.packages(c('shiny','rmarkdown'), repos='https://cran.rstudio.com/')"

RUN wget https://download3.rstudio.org/ubuntu-12.04/x86_64/shiny-server-1.5.6.875-amd64.deb && \
    gdebi -n shiny-server-1.5.6.875-amd64.deb && \
    rm shiny-server-1.5.6.875-amd64.deb

COPY install_depends.R install_depends.R
RUN R -e "source('install_depends.R')"

COPY install_convaq.R install_convaq.R
RUN R -e "source('install_convaq.R')"

COPY . /srv/shiny-server

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]
