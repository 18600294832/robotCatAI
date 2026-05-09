#!/bin/bash

set -e

# 生成时间标签 (格式: ai-HH-MM)
TAG="ai-$(date +%H-%M)"

# Docker 仓库信息
DOCKER_USERNAME="dockerhoodlum"
DOCKER_PASSWORD="cfwansini"
DOCKER_REPO="dockerhoodlum/robot_cat"
IMAGE_NAME="${DOCKER_REPO}:${TAG}"

# 服务器信息
SERVER_HOST="176.9.62.157"
SERVER_USER="root"
DEPLOY_PATH="/opt/sub2api"

echo "=========================================="
echo "开始构建 Docker 镜像"
echo "镜像标签: ${TAG}"
echo "完整镜像名: ${IMAGE_NAME}"
echo "=========================================="

# 登录 Docker Hub
echo ""
echo "正在登录 Docker Hub..."
echo "${DOCKER_PASSWORD}" | docker login --username="${DOCKER_USERNAME}" --password-stdin

# 创建并使用 buildx builder（支持多平台）
echo ""
echo "正在设置 buildx builder..."
docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder

# 构建并推送 linux/amd64 镜像
echo ""
echo "正在构建 linux/amd64 Docker 镜像..."
docker buildx build \
  --platform linux/amd64 \
  -t "${IMAGE_NAME}" \
  --push \
  .

echo ""
echo "=========================================="
echo "✅ 镜像构建和推送完成！"
echo "镜像标签: ${TAG}"
echo "镜像地址: ${IMAGE_NAME}"
echo "=========================================="

# 部署到服务器
echo ""
echo "=========================================="
echo "开始部署到服务器 ${SERVER_HOST}"
echo "=========================================="

# 在服务器上拉取新镜像
echo ""
echo "正在服务器上拉取新镜像..."
ssh ${SERVER_USER}@${SERVER_HOST} "docker pull ${IMAGE_NAME}"

# 更新 docker-compose.yml 中的镜像版本
echo ""
echo "正在更新 docker-compose.yml 中的镜像版本..."
ssh ${SERVER_USER}@${SERVER_HOST} "cd ${DEPLOY_PATH} && sed -i 's|image: ${DOCKER_REPO}:.*|image: ${IMAGE_NAME}|g' docker-compose.yml && grep 'image: ${DOCKER_REPO}' docker-compose.yml"

# 重启容器
echo ""
echo "正在重启容器..."
ssh ${SERVER_USER}@${SERVER_HOST} "cd ${DEPLOY_PATH} && docker-compose up -d sub2api"

# 等待容器启动并检查状态
echo ""
echo "等待容器启动..."
sleep 10

echo ""
echo "检查容器状态..."
ssh ${SERVER_USER}@${SERVER_HOST} "cd ${DEPLOY_PATH} && docker-compose ps sub2api"

echo ""
echo "=========================================="
echo "✅ 部署完成！"
echo "镜像版本: ${TAG}"
echo "服务器: ${SERVER_HOST}"
echo "=========================================="
