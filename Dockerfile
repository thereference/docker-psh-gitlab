FROM pjcdawkins/platformsh-cli

ADD scripts/deploy.sh .
ADD scripts/destroy.sh .
ADD scripts/setup-ssh.sh .
