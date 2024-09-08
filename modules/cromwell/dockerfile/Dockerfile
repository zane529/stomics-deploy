FROM broadinstitute/cromwell:85-f34251c

# 更新 apt 源
RUN apt-get update -y

# 安装 unzip
RUN apt-get install unzip -y

# 安装 less
RUN apt-get install -y less

# 安装 vim
RUN apt-get install -y vim

# 安装 kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# 安装 AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# 添加一个启动脚本
COPY k8s-job-template.yaml /app/k8s-job-template.yaml
COPY cromwell-k8s.conf /app/cromwell-k8s.conf
COPY simple-hello.wdl /app/simple-hello.wdl
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]