pipeline {
    agent any

    environment {
        SSH_CREDENTIALS = 'ssh-agent'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        DOCKER_HOST = '65.0.178.44'
        BUILD_DIR = "/home/ubuntu/mern-${BUILD_ID}"
        DOCKER_REGISTRY = 'chathura26322'
        DOCKER_IMAGE_BACKEND = "${DOCKER_REGISTRY}/travelblogger-backend"
        DOCKER_IMAGE_FRONTEND = "${DOCKER_REGISTRY}/travelblogger-frontend"
        ACCESS_TOKEN_SECRET = "1f775dedc439323121b94836b9cb691f97793bb86a5c8d73030e158e57e68743886caef772ed3254945fd92d11fb218fa63df3cc753d06210c092daa1acb8286"
    }

    stages {
        stage('SCM Checkout') {
            steps {
                retry(3) {
                    git branch: 'main', 
                    url: 'https://github.com/chathura26322/DevOpsTravelBlogger',
                    credentialsId: 'github-credentials'
                }
            }
        }

        stage('Verify local files') {
            steps {
                sh """ 
                    echo "Checking local files"
                    ls -la server/Dockerfile || { echo 'Server Dockerfile missing'; exit 1; }
                    ls -la client/Dockerfile || { echo 'Client Dockerfile missing'; exit 1; }
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
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                        cd ${BUILD_DIR}/server && sudo docker build -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} . &&
                        sudo docker tag ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_BACKEND}:latest"
                        
                        ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                        cd ${BUILD_DIR}/client && sudo docker build -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} . &&
                        sudo docker tag ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_FRONTEND}:latest"
                    """
                }
            }
        }
        
        stage('Push Docker Images') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub', 
                        usernameVariable: 'DOCKER_USER', 
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            echo ${DOCKER_PASS} | sudo docker login -u ${DOCKER_USER} --password-stdin"
                            
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            sudo docker push ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} &&
                            sudo docker push ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} &&
                            sudo docker push ${DOCKER_IMAGE_FRONTEND}:latest &&
                            sudo docker push ${DOCKER_IMAGE_BACKEND}:latest"
                        '''
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Create docker-compose.yml with proper environment variables
                    def composeFile = """
                        version: '3.8'
                        services:
                          frontend:
                            image: ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
                            ports:
                              - "80:3000"
                            restart: always
                            networks:
                              - app-network
                          
                          backend:
                            image: ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}
                            environment:
                              - ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
                              - NODE_ENV=production
                            ports:
                              - "5000:5000"
                            restart: always
                            networks:
                              - app-network
                        
                        networks:
                          app-network:
                            driver: bridge
                    """
                    
                    writeFile file: 'docker-compose.yml', text: composeFile
                    
                    sshagent([SSH_CREDENTIALS]) {
                        // Copy compose file to EC2
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
                        """
                        
                        // Stop any running containers, pull new images, and start
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            cd ${BUILD_DIR} && 
                            sudo docker-compose down &&
                            sudo docker-compose pull && 
                            sudo docker-compose up -d && 
                            sudo docker ps"
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
            cleanWs()
        }
        success {
            echo "Pipeline succeeded! Application deployed to ${DOCKER_HOST}"
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
        }
    }
}
