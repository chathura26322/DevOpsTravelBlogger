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
        COMPOSE_PROJECT_NAME = "travelblogger"
    }

    stages {
        stage('Nuclear Cleanup') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                        # Remove all containers using our ports
                        sudo docker ps -aq --filter publish=80 --filter publish=5000 --filter publish=27017 | xargs -r sudo docker rm -f || true
                        
                        # Remove all containers from our images
                        sudo docker ps -aq --filter ancestor=${DOCKER_IMAGE_BACKEND} | xargs -r sudo docker rm -f || true
                        sudo docker ps -aq --filter ancestor=${DOCKER_IMAGE_FRONTEND} | xargs -r sudo docker rm -f || true
                        
                        # Clean up networks and volumes
                        sudo docker network prune -f
                        sudo docker volume prune -f
                        
                        # Remove old build directory
                        rm -rf ${BUILD_DIR}
                        
                        # Clean up dangling images
                        sudo docker image prune -f"
                    """
                }
            }
        }

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
                        cd ${BUILD_DIR}/server && 
                        sudo docker build --no-cache -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} . &&
                        sudo docker tag ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_BACKEND}:latest"
                        
                        ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                        cd ${BUILD_DIR}/client && 
                        sudo docker build --no-cache -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} . &&
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
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            echo ${DOCKER_PASS} | sudo docker login -u ${DOCKER_USER} --password-stdin &&
                            sudo docker push ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} &&
                            sudo docker push ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} &&
                            sudo docker push ${DOCKER_IMAGE_FRONTEND}:latest &&
                            sudo docker push ${DOCKER_IMAGE_BACKEND}:latest"
                        """
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Generate secure MongoDB password
                    def mongoPassword = sh(script: 'openssl rand -hex 12', returnStdout: true).trim()
                    
                    def composeFile = """
                        version: '3.8'
                        services:
                          mongo:
                            image: mongo:6.0
                            container_name: travelblogger-mongo
                            restart: always
                            ports:
                              - "27017:27017"
                            volumes:
                              - mongo-data:/data/db
                            environment:
                              MONGO_INITDB_ROOT_USERNAME: admin
                              MONGO_INITDB_ROOT_PASSWORD: ${mongoPassword}
                            healthcheck:
                              test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/admin --quiet -u admin -p ${mongoPassword}
                              interval: 30s
                              timeout: 10s
                              retries: 3

                          frontend:
                            image: ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
                            container_name: travelblogger-frontend
                            ports:
                              - "80:3000"
                            restart: always
                            depends_on:
                              - backend
                            healthcheck:
                              test: ["CMD", "curl", "-f", "http://localhost:3000"]
                              interval: 30s
                              timeout: 10s
                              retries: 3
                          
                          backend:
                            image: ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}
                            container_name: travelblogger-backend
                            environment:
                              - ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
                              - NODE_ENV=production
                              - MONGO_URI=mongodb://admin:${mongoPassword}@mongo:27017/travelblogger?authSource=admin
                            ports:
                              - "5000:5000"
                            restart: always
                            depends_on:
                              mongo:
                                condition: service_healthy
                            healthcheck:
                              test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
                              interval: 30s
                              timeout: 10s
                              retries: 3

                        volumes:
                          mongo-data:
                    """
                    
                    writeFile file: 'docker-compose.yml', text: composeFile
                    
                    sshagent([SSH_CREDENTIALS]) {
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
                        """
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            cd ${BUILD_DIR} && 
                            export COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}
                            sudo docker-compose down --remove-orphans
                            sudo docker-compose up -d --force-recreate
                            sudo docker ps -a"
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                        curl -I http://localhost || echo 'Frontend not responding'
                        curl -I http://localhost:5000 || echo 'Backend not responding'
                        curl -I http://localhost:27017 || echo 'MongoDB not responding'"
                    """
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
            echo "Application successfully deployed to ${DOCKER_HOST}"
            echo "Frontend: http://${DOCKER_HOST}"
            echo "Backend API: http://${DOCKER_HOST}:5000"
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
            sshagent([SSH_CREDENTIALS]) {
                sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                    sudo docker logs travelblogger-frontend --tail 50 || true
                    sudo docker logs travelblogger-backend --tail 50 || true
                    sudo docker logs travelblogger-mongo --tail 50 || true"
                """
            }
        }
    }
}
