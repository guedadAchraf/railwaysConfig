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
                                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh '''
                        aws configure set region ${AWS_REGION}
                        aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                        aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                    '''
                }
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
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        aws ecr describe-repositories --repository-names ${AWS_ECR_REPO} --region ${AWS_REGION} || \
                        aws ecr create-repository --repository-name ${AWS_ECR_REPO} --region ${AWS_REGION}
                        docker tag ${DOCKER_IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}
                        docker tag ${DOCKER_IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:latest
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:latest
                    '''
                }
            }
        }
        
        stage('Deploy with Docker Compose') {
            steps {
                script {
                    sh '''
                        sed -i 's|build: .|image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}|g' docker-compose.yml
                        docker-compose down || true
                        docker-compose up -d
                    '''
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
                        rm -f ~/.aws/credentials || true
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
