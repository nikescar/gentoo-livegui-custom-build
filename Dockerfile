# Run Docker
# docker build -t gentoolive_img .
# docker run --private -v ./:/gentoolive gentoolive_img
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

RUN mkdir -p /etc/portage/package.keywords && \
    echo "dev-util/catalyst **" >> /etc/portage/package.keywords/catalyst && \
    echo "dev-util/catalyst \"~amd64\"" >> /etc/portage/package.accept_keywords/catalyst && \
    FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox" emerge =dev-util/catalyst-9999 eselect dev-vcs/git  \
    --autounmask-write --autounmask --autounmask-backtrack=y --backtrack=100 || true && \
    yes | etc-update --automode -3 && \
    emerge =dev-util/catalyst-9999 eselect dev-vcs/git 

ENTRYPOINT ["bash"]
CMD ["entrypoint.sh"]
