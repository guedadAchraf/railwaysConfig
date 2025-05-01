pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-north-1'
        AWS_ECR_REPO = 'keycloak-app'
        DOCKER_IMAGE_TAG = "keycloak:${BUILD_NUMBER}"
        KEYCLOAK_VERSION = '23.0.0'
    }
    
    stages {
        stage('Verify Environment') {
            steps {
                script {
                    sh '''#!/bin/bash
                        echo "Checking required tools..."
                        which docker || { echo "Docker not found!"; exit 1; }
                        which aws || { echo "AWS CLI not found!"; exit 1; }
                        which docker-compose || echo "Warning: docker-compose not found"
                    '''
                }
            }
        }
        
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
        
        stage('Login to ECR') {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    script {
                        def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                        sh "aws ecr get-login-password | docker login --username AWS --password-stdin ${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    }
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    script {
                        def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                        def ecrRepo = "${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}"
                        
                        sh """
                            # Create repository if it doesn't exist
                            aws ecr describe-repositories --repository-names ${AWS_ECR_REPO} || \
                            aws ecr create-repository --repository-name ${AWS_ECR_REPO}
                            
                            # Tag and push images
                            docker tag ${DOCKER_IMAGE_TAG} ${ecrRepo}:${BUILD_NUMBER}
                            docker tag ${DOCKER_IMAGE_TAG} ${ecrRepo}:latest
                            docker push ${ecrRepo}:${BUILD_NUMBER}
                            docker push ${ecrRepo}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy with Docker Compose') {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    script {
                        def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                        def ecrImage = "${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${AWS_ECR_REPO}:${BUILD_NUMBER}"
                        
                        sh """
                            # Update compose file with new image
                            sed -i 's|image: .*|image: ${ecrImage}|g' docker-compose.yml
                            
                            # Deploy
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
                echo "Cleaning up workspace"
                sh 'docker system prune -f || true'
            }
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed"
            // Removed slackSend as it's not available
        }
    }
}