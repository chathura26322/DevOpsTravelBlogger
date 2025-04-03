pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-credentials')
        AWS_SECRET_ACCESS_KEY = credentials('aws-credentials')
        ACCESS_TOKEN_SECRET   = credentials('access-token-secret')
    }

    stages {
        stage('SCM Checkout') {
            steps {
                retry(3) {
                    git branch: 'main', url: 'https://github.com/chathura26322/DevOpsTravelBlogger'
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh "docker build -t chathura26322/travelblogger-frontend:${env.BUILD_NUMBER} ./client"
                sh "docker build -t chathura26322/travelblogger-backend:${env.BUILD_NUMBER} ./server"
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
                sh "docker push chathura26322/travelblogger-frontend:${env.BUILD_NUMBER}"
                sh "docker push chathura26322/travelblogger-backend:${env.BUILD_NUMBER}"
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    def ec2_ip = sh(script: "cd terraform && terraform output -raw instance_public_ip", returnStdout: true).trim()
                    sh "ssh -o StrictHostKeyChecking=no -i ~/Downloads/mern-keypair.pem ec2-user@${ec2_ip} 'mkdir -p ~/app'"
                    sh "scp -i ~/Downloads/mern-keypair.pem docker-compose.yml ec2-user@${ec2_ip}:~/app/"
                    sh "scp -i ~/Downloads/mern-keypair.pem -r client ec2-user@${ec2_ip}:~/app/"
                    sh "scp -i ~/Downloads/mern-keypair.pem -r server ec2-user@${ec2_ip}:~/app/"
                    sh """
                        ssh -i ~/Downloads/mern-keypair.pem ec2-user@${ec2_ip} << 'EOF'
                        cd ~/app
                        export ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
                        /usr/local/bin/docker-compose up -d
                        EOF
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout'
        }
        failure {
            echo 'Pipeline failed!'
        }
        success {
            echo 'Pipeline succeeded!'
        }
    }
}