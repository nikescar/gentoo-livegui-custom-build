# Run Docker
# docker build -t gentoolive_img .
# docker run -v ./:/gentoolive gentoolive_img
FROM gentoo/stage3
WORKDIR /gentoolive
# ENV device pine64-pinephonePro
# RUN mkdir -p /etc/portage/repos.conf && \
#     echo "" > /etc/portage/repos.conf/gentoo.conf && \
#     cat /etc/portage/repos.conf/gentoo.conf


# download portage from repository
RUN wget https://ftp.kaist.ac.kr/gentoo/snapshots/portage-latest.tar.bz2 && \
    tar jxvf portage*.tar.bz2 && \
    mkdir -p /var/db/repos && \
    mv portage /var/db/repos/gentoo

RUN emerge catalyst eselect git

ENTRYPOINT ["bash"]
CMD ["entrypoint.sh"]