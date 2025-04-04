// pipeline {
//     agent any

//     environment {
//         SSH_CREDENTIALS = 'ssh-agent'
//         BUILD_NUMBER = "${env.BUILD_NUMBER}"
//         DOCKER_HOST = '65.0.178.44'
//         BUILD_DIR = "/home/ubuntu/mern-${BUILD_ID}"
//         DOCKER_REGISTRY = 'chathura26322'
//         DOCKER_IMAGE_BACKEND = "${DOCKER_REGISTRY}/travelblogger-backend"
//         DOCKER_IMAGE_FRONTEND = "${DOCKER_REGISTRY}/travelblogger-frontend"
//         ACCESS_TOKEN_SECRET = "1f775dedc439323121b94836b9cb691f97793bb86a5c8d73030e158e57e68743886caef772ed3254945fd92d11fb218fa63df3cc753d06210c092daa1acb8286"
//     }

//     stages {
//         stage('Clean Previous Deployment') {
//             steps {
//                 sshagent([SSH_CREDENTIALS]) {
//                     sh """
//                         ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
//                         # Remove all containers from previous deployment
//                         sudo docker-compose -f ${BUILD_DIR}/docker-compose.yml down --remove-orphans --rmi all 2>/dev/null || true
                        
//                         # Remove old build directory if exists
//                         rm -rf ${BUILD_DIR}"
//                     """
//                 }
//             }
//         }

//         stage('SCM Checkout') {
//             steps {
//                 retry(3) {
//                     git branch: 'main', 
//                     url: 'https://github.com/chathura26322/DevOpsTravelBlogger',
//                     credentialsId: 'github-credentials'
//                 }
//             }
//         }

//         stage('Verify local files') {
//             steps {
//                 sh """ 
//                     echo "Checking local files"
//                     ls -la server/Dockerfile || { echo 'Server Dockerfile missing'; exit 1; }
//                     ls -la client/Dockerfile || { echo 'Client Dockerfile missing'; exit 1; }
//                 """
//             }
//         }

//         stage('Prepare Remote Host') {
//             steps {
//                 sshagent([SSH_CREDENTIALS]) {
//                     sh """
//                         ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
//                         mkdir -p ${BUILD_DIR}/{client,server} && 
//                         chmod -R 755 ${BUILD_DIR}"
//                     """
//                     sh """
//                         scp -o StrictHostKeyChecking=no -r ./client ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
//                         scp -o StrictHostKeyChecking=no -r ./server ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
//                     """
//                 }
//             }
//         }

//         stage('Build Docker Images') {
//             steps {
//                 sshagent([SSH_CREDENTIALS]) {
//                     sh """
//                         ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
//                         cd ${BUILD_DIR}/server && sudo docker build -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} . &&
//                         sudo docker tag ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_BACKEND}:latest"
                        
//                         ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
//                         cd ${BUILD_DIR}/client && sudo docker build -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} . &&
//                         sudo docker tag ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_FRONTEND}:latest"
//                     """
//                 }
//             }
//         }
        
//         stage('Push Docker Images') {
//             steps {
//                 sshagent([SSH_CREDENTIALS]) {
//                     withCredentials([usernamePassword(
//                         credentialsId: 'dockerhub', 
//                         usernameVariable: 'DOCKER_USER', 
//                         passwordVariable: 'DOCKER_PASS'
//                     )]) {
//                         sh '''
//                             ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
//                             echo ${DOCKER_PASS} | sudo docker login -u ${DOCKER_USER} --password-stdin"
                            
//                             ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
//                             sudo docker push ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} &&
//                             sudo docker push ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} &&
//                             sudo docker push ${DOCKER_IMAGE_FRONTEND}:latest &&
//                             sudo docker push ${DOCKER_IMAGE_BACKEND}:latest"
//                         '''
//                     }
//                 }
//             }
//         }

//         stage('Deploy to EC2') {
//             steps {
//                 script {
//                     def composeFile = """
//                         version: '3.8'
//                         services:
//                           frontend:
//                             image: ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
//                             ports:
//                               - "80:3000"
//                             restart: always
                          
//                           backend:
//                             image: ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}
//                             environment:
//                               - ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
//                               - NODE_ENV=production
//                             ports:
//                               - "5000:5000"
//                             restart: always
//                     """
                    
//                     writeFile file: 'docker-compose.yml', text: composeFile
                    
//                     sshagent([SSH_CREDENTIALS]) {
//                         sh """
//                             scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
//                         """
//                         sh """
//                             ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
//                             cd ${BUILD_DIR} && 
//                             sudo docker-compose up -d"
//                         """
//                     }
//                 }
//             }
//         }
//     }

//     post {
//         always {
//             sshagent([SSH_CREDENTIALS]) {
//                 sh """
//                     ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
//                     docker logout || true"
//                 """
//             }
//             cleanWs()
//         }
//         success {
//             echo "Pipeline succeeded! Application deployed to ${DOCKER_HOST}"
//         }
//         failure {
//             echo 'Pipeline failed! Check logs for details.'
//         }
//     }
// }
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
        stage('Clean Previous Deployment') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                        # Stop and remove all containers using the specified ports
                        sudo docker ps -a -q --filter 'publish=80' --filter 'publish=5000' | xargs -r sudo docker stop || true
                        sudo docker ps -a -q --filter 'publish=80' --filter 'publish=5000' | xargs -r sudo docker rm -f || true

                        # Remove all containers from previous deployment (based on image names)
                        sudo docker ps -a -q --filter 'ancestor=${DOCKER_IMAGE_BACKEND}' | xargs -r sudo docker stop || true
                        sudo docker ps -a -q --filter 'ancestor=${DOCKER_IMAGE_BACKEND}' | xargs -r sudo docker rm -f || true
                        sudo docker ps -a -q --filter 'ancestor=${DOCKER_IMAGE_FRONTEND}' | xargs -r sudo docker stop || true
                        sudo docker ps -a -q --filter 'ancestor=${DOCKER_IMAGE_FRONTEND}' | xargs -r sudo docker rm -f || true

                        # Remove docker-compose managed containers if any remain
                        sudo docker-compose -f ${BUILD_DIR}/docker-compose.yml down --remove-orphans --rmi all 2>/dev/null || true

                        # Remove old build directory if exists
                        rm -rf ${BUILD_DIR}

                        # Optionally remove dangling images to free up space
                        sudo docker images -q -f dangling=true | xargs -r sudo docker rmi || true"
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
                    def composeFile = """
                        version: '3.8'
                        services:
                          frontend:
                            image: ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
                            ports:
                              - "80:3000"
                            restart: always
                          
                          backend:
                            image: ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}
                            environment:
                              - ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
                              - NODE_ENV=production
                            ports:
                              - "5000:5000"
                            restart: always
                    """
                    
                    writeFile file: 'docker-compose.yml', text: composeFile
                    
                    sshagent([SSH_CREDENTIALS]) {
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${DOCKER_HOST}:${BUILD_DIR}/
                        """
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DOCKER_HOST} "
                            cd ${BUILD_DIR} && 
                            sudo docker-compose up -d"
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
