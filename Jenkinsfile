pipeline {
    agent any

    environment {
        SSH_CREDENTIALS = 'ssh-agent'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        DOCKER_HOST = 'ubuntu@65.0.178.44'
        BUILD_DIR = 'home/ubuntu/mern-${BUILD_ID}
    }

    stages {
        stage('SCM Checkout') {
            steps {
                retry(3) {
                    git branch: 'main', url: 'https://github.com/chathura26322/DevOpsTravelBlogger'
                }
            }
        }

        stage('Varify local files'){
            steps{
                sh """ 
                    echo "checking local files"
                    ls -la server/Dockerfile
                    ls -la client/Dockerfile
                    cat server/Dockerfile
                """
            }
        }

        stage('Prepare Remote Host') {
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DOCKER_HOST} "
                        rm -rf ${BUILD_DIR} && 
                        mkdir -p ${BUILD_DIR}/{client,server} && 
                        chmod -R 755 ${BUILD_DIR}"
                    """
                }
            }
        }

        
stage('Build Docker Images') {
    steps {
        script {
            // Set DOCKER_HOST to your remote Docker instance
            env.DOCKER_HOST = "tcp://65.0.178.44:2375"
            
            // Build frontend
            sh "docker build -t chathura26322/travelblogger-frontend:${BUILD_NUMBER} ./client"
            
            // Build backend
            sh "docker build -t chathura26322/travelblogger-backend:${BUILD_NUMBER} ./server"
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
                    sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                sh "docker push chathura26322/travelblogger-frontend:${BUILD_NUMBER}"
                sh "docker push chathura26322/travelblogger-backend:${BUILD_NUMBER}"
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    def ec2_ip = sh(script: "cd terraform && terraform output -raw instance_public_ip", returnStdout: true).trim()
                    sh "scp -i ~/Downloads/mern-keypair.pem docker-compose.yml ec2-user@${ec2_ip}:~/"
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ~/Downloads/mern-keypair.pem ec2-user@${ec2_ip} << 'EOF'
                        export BUILD_NUMBER=${BUILD_NUMBER}
                        export ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
                        /usr/local/bin/docker-compose -f ~/docker-compose.yml up -d
                        EOF
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'  // Avoid pipeline failure if logout fails
        }
        failure {
            echo 'Pipeline failed!'
        }
        success {
            echo 'Pipeline succeeded!'
        }
    }
}
