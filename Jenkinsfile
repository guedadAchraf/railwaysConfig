pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-north-1'  // Stockholm region
        AWS_ECR_REPO = 'keycloak-app'  // Your ECR repository name
        DOCKER_IMAGE_TAG = "keycloak:${BUILD_NUMBER}"
        KEYCLOAK_VERSION = '23.0.0'  // Set your desired Keycloak version
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
                    sh "docker build --build-arg KEYCLOAK_VERSION=${KEYCLOAK_VERSION} -t ${DOCKER_IMAGE_TAG} ."
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    withAWS(region: "${AWS_REGION}", credentials: 'aws-credentials') {
                        // Get AWS account ID from credentials
                        def awsAccountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                        
                        // Login to ECR
                        sh "aws ecr get-login-password | docker login --username AWS --password-stdin ${awsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        
                        // Create repository if it doesn't exist
                        sh """
                            aws ecr describe-repositories --repository-names ${AWS_ECR_REPO} || \
                            aws ecr create-repository --repository-name ${AWS_ECR_REPO}
                        """
                        
                        // Tag and push images
                        sh """
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
            node('any') {
                script {
                    sh '''
                        docker system prune -f || true
                    '''
                }
            }
        }
        success {
            echo "Successfully built and deployed Keycloak docker container"
        }
        failure {
            echo "Failed to build or deploy Keycloak docker container"
        }
    }
}