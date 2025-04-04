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
                    writeFile file: 'docker-compose.yml', text: """
                        version: '3.8'
                        services:
                          frontend:
                            image: ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
                            ports:
                              - "3000:80"
                            restart: always
                          
                          backend:
                            image: ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}
                            environment:
                              - ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
                            ports:
                              - "5000:5000"
                            restart: always
                    """
                    
                    sshagent([SSH_CREDENTIALS]) {
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
                        """
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
