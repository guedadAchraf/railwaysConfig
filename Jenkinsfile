pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID = credentials('AWS_ACCOUNT_ID')
        AWS_REGION = 'us-east-1'  // Change this to your desired region
        ECR_REPO_NAME = 'keycloak-railways'
        ECS_CLUSTER_NAME = 'keycloak-cluster'
        DOCKER_IMAGE_NAME = 'keycloak-railways'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Configure AWS CLI') {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    sh 'aws --version'
                }
            }
        }
        
        stage('Create ECS Cluster if not exists') {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    script {
                        sh '''
                            if ! aws ecs describe-clusters --clusters ${ECS_CLUSTER_NAME} --query 'clusters[0]' --output text > /dev/null 2>&1; then
                                echo "Creating ECS cluster ${ECS_CLUSTER_NAME}"
                                aws ecs create-cluster --cluster-name ${ECS_CLUSTER_NAME}
                            else
                                echo "ECS cluster ${ECS_CLUSTER_NAME} already exists"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Create ECR Repository if not exists') {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    script {
                        sh '''
                            if ! aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} > /dev/null 2>&1; then
                                echo "Creating ECR repository ${ECR_REPO_NAME}"
                                aws ecr create-repository --repository-name ${ECR_REPO_NAME}
                            else
                                echo "ECR repository ${ECR_REPO_NAME} already exists"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}")
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    script {
                        sh '''
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                            docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${DOCKER_IMAGE_TAG}
                            docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${DOCKER_IMAGE_TAG}
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images
            sh "docker rmi ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true"
            sh "docker rmi ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${DOCKER_IMAGE_TAG} || true"
        }
    }
}