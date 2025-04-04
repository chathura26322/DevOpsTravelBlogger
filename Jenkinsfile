pipeline {
    agent any

    environment {
        SSH_CREDENTIALS = 'ssh-agent' // Changed to match your credentials ID
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        DOCKER_HOST = '65.0.178.44' // Removed 'ubuntu@' as it's not needed for DOCKER_HOST
        BUILD_DIR = "/home/ubuntu/mern-${BUILD_ID}" // Fixed missing quote and added leading slash
        DOCKER_REGISTRY = 'chathura26322'
        DOCKER_IMAGE_BACKEND = 'chathura26322/server'
        DOCKER_IMAGE_FRONTEND = 'chathura26322/client'

        
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
                            sudo docker build -t ${DOCKER_REGISTRY}/travelblogger-frontend:${BUILD_NUMBER} ./client"
                        """
                        
                        // Build backend on remote host
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            cd ${BUILD_DIR} && 
                            sudo docker build -t ${DOCKER_REGISTRY}/travelblogger-backend:${BUILD_NUMBER} ./server"
                        """
                    }
                }
            }
        }


        stage('Push Docker Images') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${DOCKER_HOST} "
                            echo \"${DOCKER_PASS}\" | docker login -u \"${DOCKER_USER}\" --password-stdin && 
                            docker push ${DOCKER_IMAGE_BACKEND}:latest && 
                            docker push ${DOCKER_IMAGE_FRONTEND}:latest"
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
