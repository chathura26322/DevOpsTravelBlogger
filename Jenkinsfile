pipeline {
    agent any

    environment {
        SSH_CREDENTIALS = 'ssh-agent' // Changed to match your credentials ID
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        DOCKER_HOST = '65.0.178.44' // Removed 'ubuntu@' as it's not needed for DOCKER_HOST
        BUILD_DIR = "/home/ubuntu/mern-${BUILD_ID}" // Fixed missing quote and added leading slash
        DOCKER_REGISTRY = 'chathura26322'
    }

    stages {
        stage('SCM Checkout') {
            steps {
                retry(3) {
                    git branch: 'main', 
                    url: 'https://github.com/chathura26322/DevOpsTravelBlogger',
                    credentialsId: 'github-credentials' // Add if using private repo
                }
            }
        }

        stage('Verify local files') {
            steps {
                sh """ 
                    echo "Checking local files"
                    ls -la server/Dockerfile || { echo 'Server Dockerfile missing'; exit 1; }
                    ls -la client/Dockerfile || { echo 'Client Dockerfile missing'; exit 1; }
                    cat server/Dockerfile
                """
            }
        }

        stage('Prepare Remote Host') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                        rm -rf ${BUILD_DIR} && 
                        mkdir -p ${BUILD_DIR}/{client,server} && 
                        chmod -R 755 ${BUILD_DIR}"
                    """
                    // Copy files to remote host
                    sh """
                        scp -o StrictHostKeyChecking=no -r ./client ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
                        scp -o StrictHostKeyChecking=no -r ./server ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
                    """
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    script {
                        // Build frontend on remote host
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            cd ${BUILD_DIR} && 
                            docker build -t ${DOCKER_REGISTRY}/travelblogger-frontend:${BUILD_NUMBER} ./client"
                        """
                        
                        // Build backend on remote host
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            cd ${BUILD_DIR} && 
                            docker build -t ${DOCKER_REGISTRY}/travelblogger-backend:${BUILD_NUMBER} ./server"
                        """
                    }
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sshagent([SSH_CREDENTIALS]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                        """
                    }
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                        docker push ${DOCKER_REGISTRY}/travelblogger-frontend:${BUILD_NUMBER} && 
                        docker push ${DOCKER_REGISTRY}/travelblogger-backend:${BUILD_NUMBER}"
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Generate dynamic compose file
                    writeFile file: 'docker-compose.yml', text: """
                        version: '3.8'
                        services:
                          frontend:
                            image: ${DOCKER_REGISTRY}/travelblogger-frontend:${BUILD_NUMBER}
                            ports:
                              - "3000:80"
                            restart: always
                          
                          backend:
                            image: ${DOCKER_REGISTRY}/travelblogger-backend:${BUILD_NUMBER}
                            environment:
                              - ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
                            ports:
                              - "5000:5000"
                            restart: always
                    """
                    
                    sshagent([SSH_CREDENTIALS]) {
                        // Copy compose file to Docker host
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
                        """
                        
                        // Deploy on Docker host
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            cd ${BUILD_DIR} && 
                            docker-compose down && 
                            docker-compose up -d && 
                            docker ps"
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            sshagent([SSH_CREDENTIALS]) {
                sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                    docker logout || true"
                """
            }
            cleanWs() // Clean Jenkins workspace
        }
        success {
            echo "Pipeline succeeded! Application deployed to ${DOCKER_HOST}"
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
        }
    }
}
