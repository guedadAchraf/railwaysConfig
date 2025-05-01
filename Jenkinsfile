pipeline {
    agent {
        label 'docker' // Make sure your agent with Docker is labeled 'docker'
    }
    
    environment {
        AWS_REGION = 'eu-north-1'
        AWS_ECR_REPO = 'keycloak-app'
        DOCKER_IMAGE_TAG = "keycloak:${BUILD_NUMBER}"
        KEYCLOAK_VERSION = '23.0.0'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Verify Docker is available
                    sh 'docker --version'
                    sh "docker build --build-arg KEYCLOAK_VERSION=${KEYCLOAK_VERSION} -t ${DOCKER_IMAGE_TAG} ."
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    withAWS(region: "${AWS_REGION}", credentials: 'aws-credentials') {
                        def awsAccountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                        
                        sh """
                            aws ecr get-login-password | docker login --username AWS --password-stdin ${awsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com
                            aws ecr describe-repositories --repository-names ${AWS_ECR_REPO} || \
                            aws ecr create-repository --repository-name ${AWS_ECR_REPO}
                            docker tag ${DOCKER_IMAGE_TAG} ${awsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}
                            docker tag ${DOCKER_IMAGE_TAG} ${awsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:latest
                            docker push ${awsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}
                            docker push ${awsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy with Docker Compose') {
            steps {
                script {
                    withAWS(region: "${AWS_REGION}", credentials: 'aws-credentials') {
                        def awsAccountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                        
                        sh """
                            sed -i 's|build: .|image: ${awsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}|g' docker-compose.yml
                            docker-compose down || true
                            docker-compose up -d
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean up Docker resources
                sh 'docker system prune -f || true'
            }
        }
    }
}