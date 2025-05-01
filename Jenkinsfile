pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-north-1'  // Stockholm region
        AWS_ACCOUNT_ID = credentials('aws-account-id')
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
        
        stage('Configure AWS CLI') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']])
                    sh 'aws configure set region ${AWS_REGION}'
                    sh 'aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}'
                    sh 'aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image with Keycloak version as build arg
                    sh "docker build --build-arg KEYCLOAK_VERSION=${KEYCLOAK_VERSION} -t ${DOCKER_IMAGE_TAG} ."
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    // Authenticate Docker to ECR
                    sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com'
                    
                    // Create the repository if it doesn't exist
                    sh '''
                        aws ecr describe-repositories --repository-names ${AWS_ECR_REPO} --region ${AWS_REGION} || \
                        aws ecr create-repository --repository-name ${AWS_ECR_REPO} --region ${AWS_REGION}
                    '''
                    
                    // Tag and push the image
                    sh "docker tag ${DOCKER_IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}"
                    sh "docker tag ${DOCKER_IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:latest"
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}"
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:latest"
                }
            }
        }
        
        stage('Deploy with Docker Compose') {
            steps {
                script {
                    // Update the docker-compose.yml file to use the ECR image
                    sh """
                    sed -i 's|build: .|image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}|g' docker-compose.yml
                    """
                    
                    // Deploy using docker-compose
                    sh "docker-compose down || true"
                    sh "docker-compose up -d"
                    
                    // Alternative: Deploy to ECS or other AWS container service
                    // You can add additional steps here for ECS deployment if needed
                }
            }
        }
    }
    
    post {
        always {
            node('any') {  // Add node block here
                script {
                    // Clean up after build
                    sh 'docker system prune -f || true'
                    sh 'rm -f ~/.aws/credentials || true'
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
